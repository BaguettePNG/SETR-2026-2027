#include <Arduino.h>
#include <RadioLib.h>
#include <SPI.h>
#include <Wire.h>
#include <Preferences.h>
#include <Adafruit_TSL2591.h>
#include "carte.h"                        // la carte : brochage, étage RF (fourni)

// Identifiants de votre nœud (mission 1), octet de poids fort en premier
uint64_t joinEUI = 0x0102030405060708;
uint64_t devEUI  = 0x441BF6FFFEF8E164;   // Votre DevEUI
uint8_t  appKey[16] = { 0x21, 0x04, 0x20, 0x04, 0x31, 0x08, 0x20, 0x03,  
                        0x21, 0x04, 0x20, 0x04, 0x31, 0x08, 0x20, 0x03 }; // Votre AppKey

RadioCarte radio(new Module(PIN_LORA_NSS, PIN_LORA_DIO1, PIN_LORA_RST, PIN_LORA_BUSY));
LoRaWANNode node(&radio, &EU868);
Adafruit_TSL2591 tsl(2591);               // capteur de lumière, adresse I2C 0x29
Preferences memoire;                      // mémoire flash non volatile

const uint8_t FPORT_UP = 10;              // Port uplink pour les mesures
const uint8_t FPORT_DOWN = 20;            // Port downlink pour les commandes
uint32_t periodeMs = 5000;                // modifiable par downlink (mission 3)

// Fonction de traitement des downlinks (Mission 3)
void traiterCommande(const uint8_t* d, size_t n) {
  Serial.print("commande reçue :");
  for (size_t i = 0; i < n; i++) Serial.printf(" %02X", d[i]);
  Serial.println();

  if (n == 3 && d[0] == 0x01) {      // Commande 0x01 : Période (en secondes)
    uint16_t s = ((uint16_t)d[1] << 8) | d[2];
    if (s >= 5 && s <= 3600) {       // Vérification des bornes (ex: 5s à 1h)
      periodeMs = (uint32_t)s * 1000UL;
      Serial.printf("période d'envoi : %u s\n", (unsigned)s);
    } else {
      Serial.println("commande refusée : période hors bornes");
    }
  } else if (n == 2 && d[0] == 0x02) { // Commande 0x02 : LED de la carte (GPIO 18)
    digitalWrite(PIN_LED, d[1] ? HIGH : LOW);
    Serial.printf("LED %s\n", d[1] ? "allumée" : "éteinte");
  } else {
    Serial.println("commande refusée : format inconnu");
  }
}

void setup() {
  Serial.begin(115200);
  delay(2000);   
  
  uint64_t mac = ESP.getEfuseMac(); 
  uint8_t m[6];
  for (int i = 0; i < 6; i++) m[i] = (uint8_t)(mac >> (8 * i));
  Serial.printf("MAC %02X:%02X:%02X:%02X:%02X:%02X -> DevEUI %02X%02X%02XFFFE%02X%02X%02X\n",
                m[0], m[1], m[2], m[3], m[4], m[5],
                m[0], m[1], m[2], m[3], m[4], m[5]);

  Wire.begin(PIN_SDA, PIN_SCL);           // TSL2591 : SDA GPIO 6, SCL GPIO 17 (annexe A)
  if (!tsl.begin()) Serial.println("TSL2591 introuvable");
  tsl.setGain(TSL2591_GAIN_MED);                 // gain x25, adapté à une salle
  tsl.setTiming(TSL2591_INTEGRATIONTIME_100MS);  // mesure en 100 ms

  pinMode(PIN_LED, OUTPUT);               // Initialisation de la LED de la carte (GPIO 18)

  SPI.begin(PIN_LORA_SCK, PIN_LORA_MISO, PIN_LORA_MOSI, PIN_LORA_NSS);
  radio.alimenterEtageRF();               // amplificateur et LNA de la carte (carte.h)
  Serial.printf("radio.begin : %d\n", radio.begin());

  node.beginOTAA(joinEUI, devEUI, NULL, appKey); // LoRaWAN 1.0.x : pas de NwkKey

  // Restaure les nonces du join précédent (voir mission 1)
  memoire.begin("lorawan", false);
  uint8_t nonces[RADIOLIB_LORAWAN_NONCES_BUF_SIZE];
  if (memoire.getBytes("nonces", nonces, sizeof(nonces)) == sizeof(nonces)) {
    node.setBufferNonces(nonces);
  }

  int16_t etat = node.activateOTAA();
  Serial.printf("activateOTAA : %d\n", etat);   

  // Sauvegarde les nonces pour le prochain démarrage
  memoire.putBytes("nonces", node.getBufferNonces(),
                   RADIOLIB_LORAWAN_NONCES_BUF_SIZE);
}

void loop() {
  uint8_t uplink[51];                     // 51 octets = maximum à SF12 en EU868
  size_t len = 0;

  // 1. Lecture du capteur TSL2591
  uint32_t lum = tsl.getFullLuminosity();   // spectre complet (16 bits bas) + infrarouge (16 bits hauts)
  uint16_t full = lum & 0xFFFF;             // spectre complet
  uint16_t ir = lum >> 16;                  // infrarouge
  float lux = tsl.calculateLux(full, ir);   // éclairement calculé en lux
  
  // Conversion en entier avec facteur d'échelle x100 (sur 2 octets signés)
  int16_t luxRaw = (int16_t)lroundf(lux * 100.0f);

  // 2. Construction de la trame binaire (Format v1 : 7 octets, Big-endian)
  uplink[0] = 0x01;                         // Type de trame : mesures
  uplink[1] = (uint8_t)(full >> 8);         // Full (MSB)
  uplink[2] = (uint8_t)(full & 0xFF);       // Full (LSB)
  uplink[3] = (uint8_t)(ir >> 8);           // IR (MSB)
  uplink[4] = (uint8_t)(ir & 0xFF);         // IR (LSB)
  uplink[5] = (uint8_t)(luxRaw >> 8);       // Lux (MSB)
  uplink[6] = (uint8_t)(luxRaw & 0xFF);     // Lux (LSB)
  len = 7;                                  // Longueur totale de la payload binaire

  Serial.print("uplink :");
  for (size_t i = 0; i < len; i++) Serial.printf(" %02X", uplink[i]);
  Serial.println();

  uint8_t downlink[16];
  size_t dlLen = 0;
  
  // Envoi de l'uplink et écoute dans les fenêtres RX1/RX2 (Classe A)
  int16_t etat = node.sendReceive(uplink, len, FPORT_UP, downlink, &dlLen);
  Serial.printf("sendReceive : %d, downlink %u octets\n", etat, dlLen);

  // 3. Traitement du downlink reçu (Mission 3)
  if (etat > 0 && dlLen > 0) {
    traiterCommande(downlink, dlLen);
  }

  delay(periodeMs);
}