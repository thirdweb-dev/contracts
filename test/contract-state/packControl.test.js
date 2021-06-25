const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Deploying the pack protocol system.", () => {

  // Pack Protocol contracts.
  let packControl
  let packERC1155
  let rng 
  let packHandler

  // Module names
  let packERC1155ModuleName
  let packHandlerModuleName

  // Signers
  let protocolAdmin;
  let creator;
  let endUser;

  before(async () => {

    // Get signers
    [protocolAdmin, creator, endUser] = await ethers.getSigners();
    
    // Deploy control center `PackControl.sol`
    const PackControl_Factory = await ethers.getContractFactory("PackControl");
    packControl = await PackControl_Factory.deploy();
    
    // Deploy core module `PackERC1155.sol`
    const PackERC1155_Factory = await ethers.getContractFactory("PackERC1155");
    packERC1155 = await PackERC1155_Factory.deploy(packControl.address);

    // 3. Deploy RNG contract
    const RNG_Factory = await ethers.getContractFactory("DexRNG");
    rng = await RNG_Factory.deploy();

    // Get `PackERC1155` module name
    packERC1155ModuleName = await packControl.PACK_ERC1155();
    rngModuleName = await packControl.PACK_RNG();
  })

  describe("Access control.", () => {
    it("Should grant 'PROTOCOL_ADMIN' role to deployer", async () => {
      const protocolAdminRole = await packControl.PROTOCOL_ADMIN();
      expect(await packControl.hasRole(protocolAdminRole, protocolAdmin.address)).to.equal(true);
    })

    it("Should emit 'RoleGranted' upon making an address a protocol admin", async () => {
      const protocolAdminRole = await packControl.PROTOCOL_ADMIN();    

      await expect(packControl.connect(protocolAdmin).makeProtocolAdmin(endUser.address))
        .to.emit(packControl, "RoleGranted")
        .withArgs(protocolAdminRole, endUser.address, protocolAdmin.address);
    })

    it("Should implement `onlyProtocolAdmin` on protected functions.", async () => {
      const protocolAdminRole = await packControl.PROTOCOL_ADMIN();
      expect(await packControl.hasRole(protocolAdminRole, creator.address)).to.equal(false);

      const randomModuleAddress = '0x419e1C9Db3a750e2e9eD0a7f70A5DdC6538a70D6';
      const randomModuleName = "RANDOM_MODULE";

      await expect(packControl.connect(creator).addModule(randomModuleName, randomModuleAddress))
        .to.be.reverted;
      
      const moduleAddedPromise = new Promise((resolve, reject) => {
        packControl.on("ModuleAdded", (_moduleName, _moduleId, _moduleAddress, event) => {
          event.removeListener()
  
          expect(_moduleName).to.equal(randomModuleName)
          expect(_moduleAddress).to.equal(randomModuleAddress);
  
          resolve();
        })
  
        setTimeout(() => {
          reject(new Error("'ModuleAdded' event timeout."));
        }, 10000);
      })
  
      await packControl.connect(protocolAdmin).makeProtocolAdmin(creator.address);
      await packControl.connect(creator).addModule(randomModuleName, randomModuleAddress)
  
      await moduleAddedPromise;
    })
  })

  describe("Initializing PackERC1155.", () => {
    it("Should emit 'ModuleAdded' upon initializing PackERC1155.", async () => {
  
      await expect(packControl.connect(protocolAdmin).initPackProtocol(packERC1155.address, rng.address))
        .to.emit(packControl, "ModuleAdded");
    })
  
    it("Should update module mappings correctly upon initializing PackERC1155.", async () => {
      // PackERC1155 already initialized in the preceding test.
  
      const packERC1155ModuleAddress = await packControl.getModule(packERC1155ModuleName);
      expect(packERC1155ModuleAddress).to.equal(packERC1155.address);

      const rngModuleAddress = await packControl.getModule(rngModuleName);
      expect(rngModuleAddress).to.equal(rng.address);
    })
  })

  describe("CRUD for arbitrary modules.", () => {
    
    before(async () => {
      // Deploy module `Pack.sol`
      const PackHandler_Factory = await ethers.getContractFactory("PackHandler");
      packHandler = await PackHandler_Factory.deploy(packERC1155.address);

      packHandlerModuleName = "PACK_HANDLER";
    })

    it("Should emit 'ModuleAdded' upon adding a module.", async () => {
      const packHandlerModuleId = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(packHandlerModuleName)
      );

      await expect(packControl.connect(protocolAdmin).addModule(packHandlerModuleName, packHandler.address))
        .to.emit(packControl, "ModuleAdded")
        .withArgs(packHandlerModuleName, packHandlerModuleId, packHandler.address);
    })

    it("Should update module mappings correctly upon adding module.", async () => {
      const packHandlerModuleId = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(packHandlerModuleName)
      );

      expect(await packControl.moduleId(packHandlerModuleName)).to.equal(packHandlerModuleId);
      expect(await packControl.modules(packHandlerModuleId)).to.equal(packHandler.address);
    })

    it("Should emit 'ModuleUpdated' upon updating a module's address.", async () => {

      const packHandlerModuleId = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(packHandlerModuleName)
      );
      const dummyAddress = creator.address;

      await expect(packControl.connect(protocolAdmin).changeModuleAddress(packHandlerModuleName, dummyAddress))
        .to.emit(packControl, "ModuleUpdated")
        .withArgs(packHandlerModuleName, packHandlerModuleId, dummyAddress);
    })

    it("Should update module mappings correctly upon updating a module's address.", async () => {
      const dummyAddress = creator.address;
      const packHandlerModuleId = await packControl.moduleId(packHandlerModuleName);
      expect(await packControl.connect(protocolAdmin).modules(packHandlerModuleId)).to.equal(dummyAddress);
    })

    it("Should emit 'ModuleUpdated' upon deleting an existing module.", async () => {

      const packHandlerModuleId = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(packHandlerModuleName)
      );
      const zeroAddress = "0x0000000000000000000000000000000000000000";

      await expect(packControl.connect(protocolAdmin).deleteModule(packHandlerModuleName))
        .to.emit(packControl, "ModuleUpdated")
        .withArgs(packHandlerModuleName, packHandlerModuleId, zeroAddress);
    })

    it("Should update module mappings correctly upon deleteing a module.", async () => {      
      const zeroAddress = "0x0000000000000000000000000000000000000000";
      expect(await packControl.connect(protocolAdmin).getModule(packHandlerModuleName)).to.equal(zeroAddress);
    })
  })
})