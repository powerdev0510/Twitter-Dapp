const Web3 = require('web3');
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));

const ClaimHolder =  artifacts.require('../contracts/ClaimHolder.sol');
const TrustedIssuersRegistry = artifacts.require('../contracts/TrustedIssuersRegistry.sol');
const ClaimTypesRegistry = artifacts.require('../contracts/ClaimTypesRegistry.sol');
const IdentityRegistry = artifacts.require('../contracts/IdentityRegistry.sol');
const TweetServices = artifacts.require('../contracts/TweetServices.sol');

function getEncodedCall(instance, method, params = []) {
  const contract = new web3.eth.Contract(instance.abi)
  return contract.methods[method](...params).encodeABI()
}

contract('IdentityRegistry', function (accounts) {
    let identityRegistry, claimTypeRegistry, trustedIssuerRegistry, tweetServices;
    let addrZero = constants.ZERO_ADDRESS;
    let issuer_EOA = accounts[0];
    let signer_key = web3.utils.keccak256(accounts[4]);
    const privateKey_signer = '---Change this to private key of accounts[4]---' // this is private key of accounts[4]
    let user1_EOA = accounts[1];
    let user2_EOA = accounts[2];
    let services_EOA = accounts[3];
    let issuer_identity, user1_Identity, user2_Identity;
    
    beforeEach(async function () {

    });
    /**
     * @notice Before we go, I would like to introduce about contract sytem,
     * @notice We have 3 actor in this system:
     * @notice 1. Issuer: Twitter issuer will sign claim for User 
     * @notice 2. User: User will use claim signed by Issuer to use Register & Tweet Services
     * @notice 3. Services Provider: SP will provide Register & Tweet Services for valid User.
     */
    describe("Identity Registry Services", function () {
    
        it("STEP 1: Deploy Twitter Issuer Identity", async function () {
            issuer_identity = await ClaimHolder.new({ from: issuer_EOA});
        });

        it("STEP 2: Twitter Issuer Add Signer Key - The key to sign Claim for User", async function () {
            await issuer_identity.addKey(signer_key, 3, 1, { from: issuer_EOA});
        });

        it("STEP 3: Services Provider deploy Trusted Issuer Registry - A contract contains list of trusted issuer", async function () {
            trustedIssuerRegistry = await TrustedIssuersRegistry.new({ from: services_EOA });
        });

         it("STEP 4: Services Provider deploy Trusted ClaimType Registry - A contract contains list of trusted claim type", async function () {
            claimTypeRegistry = await ClaimTypesRegistry.new({ from: services_EOA });
        });

         it("STEP 5: Services Provider deploy Identity Services - Twitter KYC", async function () {
            identityRegistry = await IdentityRegistry.new(trustedIssuerRegistry.address, claimTypeRegistry.address, { from: services_EOA });
        });


        it("STEP 6: User1 Deploy User1 Identity - This is like an account present user on social Network", async function () {
            user1_Identity = await ClaimHolder.new({ from: user1_EOA});
        });

        it("STEP 7: User2 Deploy User2 Identity - This is like an account present user on social Network", async function () {
            user2_Identity = await ClaimHolder.new({ from: user2_EOA});
        });
       
        it("STEP 8: Issuer sign KYC claim (claimType = 1, claimSchema = 1) by signer account and user1, user2 add Claim to them identity", async function() {
            const rawClaimData_user1 = "This is Claim for User 1, signed by Twitter";
            const hexData_user1 = web3.utils.utf8ToHex(rawClaimData_user1);
            const hashedDataToSign_user1 = web3.utils.soliditySha3(user1_Identity.address, 1, hexData_user1) // 1 is KYC Claim Type
            const signature_user1 = await web3.eth.accounts.sign(hashedDataToSign_user1, privateKey_signer);
            await user1_Identity.addClaim(
                                1,      // Claim Type 
                                1,         // Claim Schema
                                issuer_identity.address,    //Address of issuer
                                signature_user1.signature,     // sigature of claim
                                hexData_user1,       // hex data of claim
                                'https://decentralized-twitter.com', { from: user1_EOA}) // uri for link, ipfs

            const rawClaimData_user2 = "This is Claim for User 2, signed by Twitter";
            const hexData_user2 = web3.utils.utf8ToHex(rawClaimData_user2);
            const hashedDataToSign_user2 = web3.utils.soliditySha3(user2_Identity.address, 1, hexData_user2) // 1 is KYC Claim Type
            const signature_user2 = await web3.eth.accounts.sign(hashedDataToSign_user2, privateKey_signer);
            await user2_Identity.addClaim(
                                1,      // Claim Type 
                                1,         // Claim Schema
                                issuer_identity.address,    //Address of issuer
                                signature_user2.signature,     // sigature of claim
                                hexData_user2,       // hex data of claim
                                'https://decentralized-twitter.com', { from: user2_EOA}) // uri for link, ipfs
        });

        it("STEP 9: Services Provider add trusted ClaimType (1) & trusted Issuer (issuer_identity)", async function () {
            await trustedIssuerRegistry.addTrustedIssuer(issuer_identity.address, 1,  {from: services_EOA});
            await claimTypeRegistry.addClaimType(1, {from: services_EOA});
        });

        it("STEP 10: User1 now had ClaimSigned by Twitter Issuer, can use register services on IdentityRegistry contract", async function() {
            const registerData_user1 = getEncodedCall(identityRegistry, 'registerIdentity', [user1_Identity.address]);
            await  user1_Identity.execute(identityRegistry.address, 0, registerData_user1, { from: user1_EOA});
            const res = await identityRegistry.identity.call(user1_Identity.address); // 0 is id of user1_Identity on identityRegistry
            console.log("xxxxx ress", res)
            assert.equal(res, true)
        });

        it("STEP 11: User2 now had ClaimSigned by Twitter Issuer, can use register services on IdentityRegistry contract", async function() {
           const registerData_user2 = getEncodedCall(identityRegistry, 'registerIdentity', [user2_Identity.address]);
           await user2_Identity.execute(identityRegistry.address, 0, registerData_user2, { from: user2_EOA});
           const res = await identityRegistry.identity.call(user2_Identity.address); // 1 is id of user2_Identity on identityRegistry
           assert.equal(res, true)
        });
    })  

    describe("Tweet Services", function () {

        it("STEP 12: Services Provider Deploy TweetServices from services's EOA", async function() {
            tweetServices = await TweetServices.new(identityRegistry.address, { from: services_EOA});
        });

        it("STEP 13: User 1 now can post new tweet", async function() {
            const content = web3.utils.asciiToHex("This is my first tweet on Decentralized Twitter app");
            const tweetData = getEncodedCall(tweetServices, 'tweetNewPost', [content]);
            await user1_Identity.execute(tweetServices.address, 0, tweetData, {from: user1_EOA});
        });

        it("STEP 14: User 2 comment on first tweet of User 1", async function () {
            const comment = web3.utils.asciiToHex("Thank you for your useful tweet, i would like to re-tweet it");
            const commentData = getEncodedCall(tweetServices, 'commentOnTweet', [user1_Identity.address, 1, comment]);
            await user2_Identity.execute(tweetServices.address, 0, commentData, {from: user2_EOA});
        })

        it("STEP 15: User 2 retweet first tweet from User 1", async function() {
            const reTweetData = getEncodedCall(tweetServices, 'reTweet', [user1_Identity.address, 1]);
            await user2_Identity.execute(tweetServices.address, 0, reTweetData, {from: user2_EOA});
        });

        it("STEP 16: After retweet action from User2, User1 now have 1 token from re-tweet action of User 2", async function () {
            const user1_tokenBalance = await tweetServices.balanceOf.call(user1_Identity.address);
            assert.isTrue(user1_tokenBalance.toNumber() == 1);
        })

        it("STEP 17: Get first tweet of User1 and check it", async function () {
            const user1_firstTweet = await tweetServices.tweets.call(user1_Identity.address, 1);

            assert.equal(user1_firstTweet.tweetId.toNumber(), 1);
            assert.isTrue(user1_firstTweet.tweeter.toString() == user1_Identity.address.toString());
            assert.isTrue(web3.utils.hexToAscii(user1_firstTweet.content) == "This is my first tweet on Decentralized Twitter app");
        })

        it("STEP 18: Get first tweet (reTweet from User1) of User2  and check it", async function () {
            const user2_firstTweet = await tweetServices.tweets.call(user2_Identity.address, 1);

            assert.equal(user2_firstTweet.tweetId.toNumber(), 1);
            assert.isTrue(user2_firstTweet.tweeter.toString() == user1_Identity.address.toString());
            assert.isTrue(web3.utils.hexToAscii(user2_firstTweet.content) == "This is my first tweet on Decentralized Twitter app");
        })

        it("OTHER: User3 deploy Identity contract but do not have valid Claim signed by Issuer, can not use Register & TweetServices", async function () {
            const user3_EOA = accounts[6];
            const user3_Identity = await ClaimHolder.new({from: user3_EOA});

            const registerData_user3 = getEncodedCall(identityRegistry, 'registerIdentity', [user3_Identity.address]);
            const tx =  await user3_Identity.execute(identityRegistry.address, 0, registerData_user3, { from: user3_EOA});
            const valueInBN = new BN(0);
            expectEvent(tx, 'ExecutionFailed', {
                executionId: valueInBN, 
                to: identityRegistry.address,
                value: valueInBN, 
                data: registerData_user3
             }
            );
        });
    });
});