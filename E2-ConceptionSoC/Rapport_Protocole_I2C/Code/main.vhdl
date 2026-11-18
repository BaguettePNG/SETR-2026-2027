action GestionHorloge sur CLK avec
(entrée var nRST : bit,
 entrée var Config : DefConfig,
 entrée var Actif, Pause : bit,         -- venant d'EmissionReception
 entrée/sortie var SCL : bit,
 sortie var SCL_Interne : bit,          -- niveau réel de SCL (après clock stretching)
 sortie var Mi_Haut : bit)              -- impulsion au milieu de la phase haute

const DIV_100K = F_CLK / 200_000;       -- f_SCL = F_CLK / (2 x Div)
const DIV_400K = F_CLK / 800_000;       -- (arrondir pour rester <= f_SCL visée)
const DIV_1M   = F_CLK / 2_000_000;
const DIV_3M4  = F_CLK / 6_800_000;
var cpt, Div : entier;
var phase : bit;

begin
  cycle :
    CLK : begin
      Mi_Haut := 0;
      if nRST = 0 or Config.Enable = 0 or Actif = 0 then
        cpt := 0; phase := 1; SCL := 1;
        case Config.Speed of            -- "non synchronisé" : figé tant qu'aucune transaction
          0 : Div := DIV_100K;  1 : Div := DIV_400K;
          2 : Div := DIV_1M;    3 : Div := DIV_3M4;
        end case;
      else
        if phase = 1 and SCL = 0 then
          rien;                         -- clock stretching : l'esclave retient SCL, on gèle
        elsif phase = 0 and Pause = 1 then
          cpt := 0;                     -- pause du maître : SCL reste bas, phase basse complète à la reprise
        else
          if cpt >= Div - 1 then
            cpt := 0; phase := not phase;
          else
            cpt := cpt + 1;
          end if;
          if phase = 1 and cpt = Div / 2 then Mi_Haut := 1; end if;
        end if;
        SCL := phase;
      end if;
      SCL_Interne := SCL;               -- lecture de la ligne (à resynchroniser sur CLK)
    end
end

action EmissionReceptionI2C sur CLK avec
(entrée ev DataReq : DefRequest,
 entrée var DataToSend : DefData,
 sortie var DataReceived : DefData,
 entrée var Config : DefConfig,
 sortie var Status : DefStatus,
 sortie ev IT_I2C,
 entrée var nRST : bit,
 entrée var SCL_Interne, Mi_Haut : bit,
 sortie var Actif, Pause : bit,
 entrée/sortie var SDA : bit)

var Etat : (AUTRE, START, ADDR, ACK_ADDR, WRITE, ACK_WRITE, ATTENTE, READ, ACK_READ, STOP);
var bit_cnt, bytes_cnt, NbOctets : entier;
var shreg : mot8;
var ReqType : DefRequest;
var RecSlave : (ACK, NAK);
var SCL_prec, FM, FD : bit;

begin
  cycle :
    CLK : begin
      FM := (SCL_prec = 0 and SCL_Interne = 1);        -- front montant de SCL
      FD := (SCL_prec = 1 and SCL_Interne = 0);        -- front descendant de SCL
      SCL_prec := SCL_Interne;

      if nRST = 0 then
        Etat := AUTRE; SDA := 1; Actif := 0; Pause := 0;
        Status := 0; DataReceived := 0;
      else
        case Etat of

          AUTRE :
            if reçu(DataReq) then
              ReqType := lire(DataReq);
              if Config.Enable = 1 then                -- sinon la demande est ignorée
                Status := 0;                           -- nouvelle transaction
                NbOctets := Config.NbBytes + 1;
                bit_cnt := 0; bytes_cnt := 0;
                shreg[7:1] := Config.ADDR;
                if ReqType = Read then shreg[0] := 1; else shreg[0] := 0; end if;
                SDA := 0;                              -- condition START (SCL est haut)
                Actif := 1;                            -- GestionHorloge démarre SCL
                Etat := START;
              end if;
            end if;

          START :
            if FD then
              SDA := shreg[7]; bit_cnt := 1;           -- 1er bit de l'adresse
              Etat := ADDR;
            end if;

          ADDR :
            if FD then
              if bit_cnt < 8 then
                SDA := shreg[7 - bit_cnt]; bit_cnt := bit_cnt + 1;   -- ADDR[6:0] puis R/W
              else
                SDA := 1;                              -- on relâche pour l'ACK de l'esclave
                Etat := ACK_ADDR;
              end if;
            end if;

          ACK_ADDR :
            if FM then
              if SDA = 0 then RecSlave := ACK; else RecSlave := NAK; end if;
            end if;
            if FD then
              if RecSlave = ACK then
                if ReqType = Write then
                  shreg := DataToSend;
                  SDA := DataToSend[7]; bit_cnt := 1;
                  Etat := WRITE;
                else
                  shreg := 0; bit_cnt := 0;            -- SDA reste relâchée : l'esclave émet
                  Etat := READ;
                end if;
              else                                     -- NAK sur l'adresse
                if ReqType = Write then Status.EmissionError := 1;
                else Status.ReceptionError := 1; end if;
                if Config.IntMode /= 0 then émettre(IT_I2C); end if;
                SDA := 0; Etat := STOP;
              end if;
            end if;

          WRITE :
            if FD then
              if bit_cnt < 8 then
                SDA := shreg[7 - bit_cnt]; bit_cnt := bit_cnt + 1;
              else
                SDA := 1;
                Etat := ACK_WRITE;
              end if;
            end if;

          ACK_WRITE :
            if FM then
              if SDA = 0 then RecSlave := ACK; else RecSlave := NAK; end if;
            end if;
            if FD then
              if RecSlave = ACK then
                bytes_cnt := bytes_cnt + 1;
                if Config.IntMode[0] = 1 then émettre(IT_I2C); end if;   -- IT à l'émission d'un octet
                if bytes_cnt < NbOctets then
                  Pause := 1;                          -- SCL maintenu bas jusqu'à l'octet suivant
                  Etat := ATTENTE;
                else
                  Status.EmissionOK := 1;
                  SDA := 0; Etat := STOP;
                end if;
              else
                Status.EmissionError := 1;
                if Config.IntMode /= 0 then émettre(IT_I2C); end if;
                SDA := 0; Etat := STOP;
              end if;
            end if;

          ATTENTE :                                    -- attente d'un nouvel écrit dans DATA_W
            if reçu(DataReq) then
              ReqType := lire(DataReq);
              shreg := DataToSend;
              SDA := DataToSend[7]; bit_cnt := 1;
              Pause := 0;
              Etat := WRITE;
            end if;

          READ :
            if FM and bit_cnt < 8 then
              shreg[7 - bit_cnt] := SDA;               -- échantillonnage sur front montant
              bit_cnt := bit_cnt + 1;
            elsif FD and bit_cnt = 8 then
              bytes_cnt := bytes_cnt + 1;
              DataReceived := shreg;
              if Config.IntMode[1] = 1 then émettre(IT_I2C); end if;     -- IT à la réception d'un octet
              if bytes_cnt < NbOctets then SDA := 0;   -- ACK du maître
              else SDA := 1; end if;                   -- NAK sur le dernier octet
              Etat := ACK_READ;
            end if;

          ACK_READ :
            if FD then
              if bytes_cnt < NbOctets then
                SDA := 1; bit_cnt := 0;                -- on relâche, octet suivant
                Etat := READ;
              else
                Status.ReceptionOK := 1;
                SDA := 0; Etat := STOP;                -- SDA bas pendant SCL bas
              end if;
            end if;

          STOP :
            if Mi_Haut = 1 and SCL_Interne = 1 then
              SDA := 1;                                -- condition STOP : SDA monte, SCL haut
              Actif := 0;                              -- SCL reste relâché (haut)
              Etat := AUTRE;
            end if;

        end case;
      end if;
    end
end

action Write sur CLK avec
(entrée var DBus : mot16,
 entrée var Addr : mot2,                 -- Addr[2:1], Addr[1] = poids faible
 entrée var nAS, RnW, nRST, nCS_I2C : bit,
 entrée var nBE0, nBE1 : bit,            -- nBE0 : D[7:0], nBE1 : D[15:8]
 sortie var Config : DefConfig,
 sortie var DataToSend : mot8,
 sortie ev DataReq : DefRequest)

begin
  cycle :
    CLK : begin
      if nRST = 0 then
        Config := 0x0000; DataToSend := 0x00;
      elsif nCS_I2C = 0 and nAS = 0 and RnW = 0 then   -- écriture, 1 cycle
        case Addr of
          "00" :                                       -- Config (0x00)
            if nBE1 = 0 then Config[15:9] := DBus[15:9]; end if;   -- ADDR
            if nBE0 = 0 then Config[6:0]  := DBus[6:0];  end if;   -- Speed, NbBytes, IntMode, Enable
          "01" : rien;                                 -- Status (0x02), géré par le contrôleur
          "10" : envoyer(DataReq, Read);               -- DATA_R (0x04) : demande de lecture
          "11" : if nBE0 = 0 then                      -- DATA_W (0x06) : demande d'écriture
                   DataToSend := DBus[7:0];
                   envoyer(DataReq, Write);
                 end if;
        end case;
      end if;
    end
end

-- Partie combinatoire : lecture en 1 cycle, sans attente
bloc Read_comb (Addr, nAS, RnW, nCS_I2C, nBE0, nBE1, Config, Status, DataReceived, DataToSend) -> DBus

  if nCS_I2C = 0 and nAS = 0 and RnW = 1 then
    case Addr of
      "00" : DBus := Config;                           -- bits réservés lus à 0
      "01" : DBus := "000000000000" & Status[3:0];     -- EmissionOK, ReceptionOK, EmissionError, ReceptionError
      "10" : DBus := 0x00 & DataReceived;
      "11" : DBus := 0x00 & DataToSend;
    end case;
    if nBE0 = 1 then DBus[7:0]  := Z; end if;          -- on ne pilote que les octets demandés
    if nBE1 = 1 then DBus[15:8] := Z; end if;
  else
    DBus := Z;
  end if;

-- Partie séquentielle : demande d'interruption
action Read_IT sur CLK avec
(entrée ev IT_I2C, entrée var Addr : mot2,
 entrée var nAS, RnW, nRST, nCS_I2C : bit,
 sortie var nIT_I2C : bit)

begin
  cycle :
    CLK : begin
      if nRST = 0 then
        nIT_I2C := 1;
      elsif reçu(IT_I2C) then
        nIT_I2C := 0;                                  -- demande d'interruption
      elsif nCS_I2C = 0 and nAS = 0 and RnW = 1 and Addr = "01" then
        nIT_I2C := 1;                                  -- acquittement : lecture de Status
      end if;
    end
end