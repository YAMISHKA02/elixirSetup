#!/bin/bash

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
NC='\033[0m'

command_exists() {
    command -v "$1" &> /dev/null
}
 #!/bin/bash

cat << "EOF"
                                                                                                                                                                                                        
                                                                                                                                                                                                        
                                                                                                                                                                                                        
                                                                                                                                                                                                        
   ########                ######################* .########            ########*  .######################    ########                            ########          ########     ###################.   
 (.########              (,######################(#,,########         *(#######* ,#.######################  ( ########                          # ########        # ########   # #####################( 
 (.########              (,######################.,# *#######/       #/#######/  ,#.#####################(  ( ########                          # ########        # ########   # #######(     ,#########
 (.########              (,########*///////////    .# *#######*     #,#######/   ,#.#######////////////*    ( ########                          # ########        # ########   # #######(    /# (#######
 (.########              (,########                 *# *#######,   * #######(    ,#.#######/                ( ########                          # ########        # ########   # #######(     # ########
 (.########              (,###################,      *#./#######  *.#######(     ,#.###################     ( ########                          # ########        # ########   # ######################/
 (.########              (,###################,       *# /#######,.(######(      ,#.###################     ( ########                          # ########        # ########   # ####################/  
 (.########              (,########                    *# (###############       ,#.#######/                ( ########                          # ########        # ########   # ################(*     
 (.########              (,########                     /# *############(        ,#.#######/                ( ########                          # (#######/       */########   # #######(,,,,,,.        
 (.####################  (,#######################       *#.(###########         ,#.######################, ( ####################              /# ########################    # #######(               
 (.####################  (,#######################        (# (#########          ,#.######################, ( ####################               (# /####################(     # #######(               
 (.####################  (,#######################         *# ########           ,#.######################, ( ####################                 ##( *##############*.       # #######(               
 (/,,,,,,,,,,,,,,,,,,    (######################            (######(             ,######################,   (,,,,,,,,,,,,,,,,,,,                      /###/*,,,,,*((,          #,,,,,,.                 
                                                                                                                                                                                                        
                                                                                                                                                                                                        
                                                                                                                                                                                                        

EOF


if command_exists nvm; then
    echo -e "${GREEN}NVM is already installed.${NC}"
else
    echo -e "${YELLOW}Installing NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

if command_exists node; then
    echo -e "${GREEN}Node.js is already installed: $(node -v)${NC}"
else
    echo -e "${YELLOW}Installing Node.js...${NC}"
    nvm install node
    nvm use node
    echo -e "${GREEN}Node.js installed: $(node -v)${NC}"
fi

echo ""

echo -e "${BOLD}${CYAN}Checking for ethers package installation...${NC}"
if ! npm list ethers &> /dev/null; then
    echo -e "${RED}ethers package not found. Installing ethers package...${NC}"
    npm install ethers
    echo -e "${GREEN}ethers package installed successfully.${NC}"
else
    echo -e "${GREEN}ethers package is already installed.${NC}"
fi


echo -e "${BOLD}${CYAN}Checking for Docker installation...${NC}"
if ! command_exists docker; then
    echo -e "${RED}Docker is not installed. Installing Docker...${NC}"
    sudo apt update && sudo apt install -y curl net-tools
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    echo -e "${GREEN}Docker installed successfully.${NC}"
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

echo -e "${BOLD}${CYAN}Generating Validator wallet...${NC}"
cat << 'EOF' > generate_wallet.js
const { Wallet } = require('ethers');
const fs = require('fs');

const wallet = Wallet.createRandom();
const mnemonic = wallet.mnemonic.phrase;
const address = wallet.address;
const privateKey = wallet.privateKey;

const walletData = `
Mnemonic: ${mnemonic}
Address: ${address}
Private Key: ${privateKey}
`;

const filePath = 'validator_wallet.txt';
fs.writeFileSync(filePath, walletData);

console.log('');
console.log('Validator Wallet Mnemonic Phrase:', mnemonic);
console.log('Validator Wallet Address:', address);
console.log('Validator Wallet Private Key:', privateKey);
console.log('\x1B[32mWallet credentials saved to \x1b[35m validator_wallet.txt\x1B[0m');
EOF

node generate_wallet.js
echo ""

ENV_FILE="validator.env"

echo -e "${BOLD}${CYAN}Creating environment variable file: ${ENV_FILE}${NC}"
echo "ENV=testnet-3" > $ENV_FILE
IP_ADDRESS=$(curl -s ifconfig.me)
echo "STRATEGY_EXECUTOR_IP_ADDRESS=$IP_ADDRESS" >> $ENV_FILE
echo ""

read -p "Enter the display name for your validator : " DISPLAY_NAME
echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$DISPLAY_NAME" >> $ENV_FILE

read -p "Enter the wallet address to receive validator rewards: " BENEFICIARY
echo "STRATEGY_EXECUTOR_BENEFICIARY=$BENEFICIARY" >> $ENV_FILE
echo ""
PRIVATE_KEY=$(grep "Private Key:" validator_wallet.txt | awk -F': ' '{print $2}' | sed 's/^0x//')
VALIDATOR_ADDRESS=$(grep "Address:" validator_wallet.txt | awk -F': ' '{print $2}')
echo "SIGNER_PRIVATE_KEY=$PRIVATE_KEY" >> $ENV_FILE

echo ""
echo -e "${BOLD}${CYAN}The $ENV_FILE file has been created with the following contents:${NC}"
cat $ENV_FILE
echo ""

echo -e "${BOLD}${YELLOW}1.Visit: https://testnet-3.elixir.xyz/${NC}"
echo -e "${BOLD}${YELLOW}2.Connect a wallet which has Sepolia Ethereum (this wallet should not be your validator wallet address).${NC}"
echo -e "${BOLD}${YELLOW}3.Mint MOCK Elixir Tokens On Sepolia${NC}"
echo -e "${BOLD}${YELLOW}4.Stake Your MOCK Tokens${NC}"
echo -e "${BOLD}${YELLOW}5.Now click on custom validator,and enter your validator wallet address : $VALIDATOR_ADDRESS for delegation${NC}"
echo ""

read -p "Have you completed the above steps?? (y/n): " response
if [[ "$response" =~ ^[yY]$ ]]; then
    echo -e "${BOLD}${CYAN}Pulling Elixir Protocol Validator Image...${NC}"
    docker pull elixirprotocol/validator:v3
else
    echo -e "${RED}Task not completed. Exiting script.{NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${CYAN}Running Docker...${NC}"
docker run -d --env-file validator.env --name elixir -p 17690:17690 --restart unless-stopped elixirprotocol/validator:v3
echo ""
echo -e "${BOLD}${CYAN}Script execution is completed successfully${NC}"
