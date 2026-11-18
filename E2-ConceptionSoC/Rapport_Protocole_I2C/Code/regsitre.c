typedef short REG;

typedef struct _S_I2C {
    REG CONFIG;
    REG STATUS;
    REG DATA_R;
    REG DATA_W;
} S_I2C, *PS_I2C;

//BASE ADDRESS
#define I2C_BASEADRESS 0x___ // I2C Controller base address

//CONFIG Register
#define CONFIG_ADDR_MASK 9 // Address mask
#define CONFIG_ADDR(uint8_t addr) ((unsigned int)addr & 0x7F) << CONFIG_ADDR_MASK // Address in 7 bits

#define CONFIG_SPEED_MASK 5 // Speed mask
#define SPEED_100KHz 0b00 // Speed 100kHz
#define SPEED_400KHz 0b01 // Speed 400kHz
#define SPEED_1MHz   0b10 // Speed 1MHz
#define SPEED_3_4MHz 0b11 // Speed 3.4MHz

#define CONFIG_SPEED_100KHz SPEED_100KHz << CONFIG_SPEED_MASK
#define CONFIG_SPEED_400KHz SPEED_400KHz << CONFIG_SPEED_MASK
#define CONFIG_SPEED_1MHz   SPEED_1MHz   << CONFIG_SPEED_MASK
#define CONFIG_SPEED_3_4MHz SPEED_3_4MHz << CONFIG_SPEED_MASK

#define CONFIG_NBBYTES_MASK 3 // Number of bytes to transfer
#define NBBYTES_8bits 0b00 // 8 bits
#define NBBYTES_16bits 0b01 // 16 bits
#define NBBYTES_24bits 0b10 // 24 bits
#define NBBYTES_32bits 0b11 // 32 bits

#define CONFIG_NBBYTES_8bits  NBBYTES_8bits  << CONFIG_NBBYTES_MASK
#define CONFIG_NBBYTES_16bits NBBYTES_16bits << CONFIG_NBBYTES_MASK
#define CONFIG_NBBYTES_24bits NBBYTES_24bits << CONFIG_NBBYTES_MASK
#define CONFIG_NBBYTES_32bits NBBYTES_32bits << CONFIG_NBBYTES_MASK

#define CONFIG_INTMODE_MASK 1       // Interrupt mode mask
#define INTMODE_DISABLED    0b00    // Interrupt disabled
#define INTMODE_EMITION     0b01    // Interrupt enabled
#define INTMODE_RECEPTION   0b10    // Interrupt enabled
#define INTMODE_BOTH        0b11    // Interrupt enabled

#define CONFIG_INTMODE_DISABLED  INTMODE_DISABLED  << CONFIG_INTMODE_MASK
#define CONFIG_INTMODE_EMITION   INTMODE_EMITION   << CONFIG_INTMODE_MASK
#define CONFIG_INTMODE_RECEPTION INTMODE_RECEPTION << CONFIG_INTMODE_MASK
#define CONFIG_INTMODE_BOTH      INTMODE_BOTH      << CONFIG_INTMODE_MASK

#define CONFIG_ENABLE_MASK 0    // Enable mask
#define ENABLED  0b1            // I2C enabled
#define DISABLED 0b0            // I2C disabled

#define CONFIG_ENABLE ENABLED  << CONFIG_ENABLE_MASK
#define CONFIG_DISABLE DISABLED << CONFIG_ENABLE_MASK

//Status Register
#define STATUS_EMISSION_OK      0x1 << 3
#define STATUS_RECEPTION_OK     0x1 << 2
#define STATUS_EMISSION_NOK     0x1 << 1
#define STATUS_RECEPTION_NOK    0x1 << 0

// Data Read
#define DATA_READ_MASK 0 // Data mask
#define DATA_READ(uint8_t data) ((unsigned int)data & 0xFF) << DATA_READ_MASK // Address in 7 bits

// Data Write
#define DATA_WRITE_MASK 0 // Data mask
#define DATA_WRITE(uint8_t data) ((unsigned int)data & 0xFF) << DATA_WRITE_MASK // Address in 7 bits

// Procedures Bas Niveau

unsigned int I2C_ReadData(PS_I2C i2c)
{
    return DATA_READ(i2c->DATA_R);
}

unsigned int I2C_WriteData(PS_I2C i2c, uint8_t data)
{
    return DATA_WRITE(data);
}