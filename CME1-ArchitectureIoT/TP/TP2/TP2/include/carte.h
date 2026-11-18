/*
  CME1 - TP2 : particularités de la carte Heltec Wireless Tracker V2.
  Fichier fourni avec le squelette : à laisser dans le dossier du croquis, à ne pas modifier.

  Sur cette carte, le SX1262 n'est pas relié directement à l'antenne : un étage RF KCT8103L
  (amplificateur d'émission + LNA de réception) est intercalé. Il doit être alimenté et validé,
  et son gain doit être retiré de la puissance demandée par la pile LoRaWAN.
  Trois broches lui sont réservées (GPIO 4, 5 et 7) : ne rien câbler dessus.
*/
#pragma once
#include <RadioLib.h>

// ---------- Brochage ----------
const int PIN_LORA_NSS  = 8;
const int PIN_LORA_DIO1 = 14;
const int PIN_LORA_RST  = 12;
const int PIN_LORA_BUSY = 13;
const int PIN_LORA_SCK  = 9;
const int PIN_LORA_MISO = 11;
const int PIN_LORA_MOSI = 10;
const int PIN_SDA       = 6;     // I2C par défaut de la carte : BME280 ou TSL2591
const int PIN_SCL       = 17;
const int PIN_LED       = 18;
const int PIN_VEXT      = 3;     // alimentation de l'écran, active à l'état haut
const int PIN_FEM_VCC   = 7;     // alimentation de l'étage RF
const int PIN_FEM_CSD   = 4;     // validation de l'étage RF
const int PIN_FEM_CTX   = 5;     // haut : émission par l'amplificateur, réception sans LNA

// Gain de l'amplificateur d'émission (dB). La pile LoRaWAN raisonne en puissance rayonnée
// (16 dBm au plus en EU868) : on programme donc le SX1262 13 dB plus bas.
const int8_t GAIN_FEM_DB = 13;

class RadioCarte : public SX1262 {
  public:
    using SX1262::SX1262;

    // Alimente et valide l'étage RF. À appeler une fois, avant radio.begin().
    void alimenterEtageRF() {
      pinMode(PIN_FEM_VCC, OUTPUT);
      digitalWrite(PIN_FEM_VCC, HIGH);
      pinMode(PIN_FEM_CSD, OUTPUT);
      digitalWrite(PIN_FEM_CSD, HIGH);
      pinMode(PIN_FEM_CTX, OUTPUT);
      digitalWrite(PIN_FEM_CTX, HIGH);
    }

    // Appelée par la pile LoRaWAN avant chaque émission
    int16_t setOutputPower(int8_t puissance) override {
      int16_t p = puissance - GAIN_FEM_DB;
      if (p < -9) p = -9;                      // minimum du SX1262
      return SX1262::setOutputPower((int8_t)p);
    }

    // Coupe la radio et l'étage RF avant une veille profonde
    void eteindre() {
      sleep();
      digitalWrite(PIN_FEM_CSD, LOW);
      digitalWrite(PIN_FEM_VCC, LOW);
    }
};
