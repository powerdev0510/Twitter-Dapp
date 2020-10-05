# Twitter-Dapp
This is a PoC Smart contract system of Decentralized Twitter Application, based on ERC725/735 and ERC20.

## Contract Architecture
- Link: https://drive.google.com/file/d/1U6Dv4jB5SNWCUGWhxMLbb_EImXZVugbE/view?usp=sharing
## Requirement
- Truffle
- Ganache 
- Node V12.11.0
- Yarn 1.19.1

## Install
- yarn install

## Run
- Quick start Ganache on port 8545
- Get private key of ```account[4]``` (account with index number 4 in accounts tab ) and change paste to ```privateKey_signer``` in *test/DecentralizedTwitter.test.js*
- Run from terminal: truffle test
##
You will see the following output of test as below, its show step by step how this system work:
Identity Registry Services
-  STEP 1: Deploy Twitter Issuer Identity 
-  STEP 2: Twitter Issuer Add Signer Key - The key to sign Claim for User 
-  STEP 3: Services Provider deploy Trusted Issuer Registry - A contract contains list of trusted issuer 
-  STEP 4: Services Provider deploy Trusted ClaimType Registry - A contract contains list of trusted claim type 
-  STEP 5: Services Provider deploy Identity Services - Twitter KYC 
-  STEP 6: User1 Deploy User1 Identity - This is like an account present user on social Network 
-  STEP 7: User2 Deploy User2 Identity - This is like an account present user on social Network 
-  STEP 8: Issuer sign KYC claim (claimType = 1, claimSchema = 1) by signer account and user1, user2 add Claim to them identity 
- STEP 9: Services Provider add trusted ClaimType (1) & trusted Issuer (issuer_identity) 
- STEP 10: User1 now had ClaimSigned by Twitter Issuer, can use register services on IdentityRegistry contract 
- STEP 11: User2 now had ClaimSigned by Twitter Issuer, can use register services on IdentityRegistry contract 
    Tweet Services
- STEP 12: Services Provider Deploy TweetServices from services's EOA 
- STEP 13: User 1 now can post new tweet 
- STEP 14: User 2 comment on first tweet of User 1 
- STEP 15: User 2 retweet first tweet from User 1 
- STEP 16: After retweet action from User2, User1 now have 1 token from re-tweet action of User 2 
- STEP 17: Get first tweet of User1 and check it
- STEP 17: Get first tweet (reTweet from User1) of User2  and check it
- OTHER: User3 deploy Identity contract but do not have valid Claim signed by Issuer, can not use Register & TweetServices 
