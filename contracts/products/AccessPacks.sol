// ░█████╗░  ░█████╗░  ░█████╗░  ███████╗  ░██████╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██╔════╝  ██╔════╝  ██╔════╝
// ███████║  ██║░░╚═╝  ██║░░╚═╝  █████╗░░  ╚█████╗░  ╚█████╗░
// ██╔══██║  ██║░░██╗  ██║░░██╗  ██╔══╝░░  ░╚═══██╗  ░╚═══██╗
// ██║░░██║  ╚█████╔╝  ╚█████╔╝  ███████╗  ██████╔╝  ██████╔╝
// ╚═╝░░╚═╝  ░╚════╝░  ░╚════╝░  ╚══════╝  ╚═════╝░  ╚═════╝░


// ██████╗░  ░█████╗░  ░█████╗░  ██╗░░██╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██║░██╔╝  ██╔════╝
// ██████╔╝  ███████║  ██║░░╚═╝  █████═╝░  ╚█████╗░
// ██╔═══╝░  ██╔══██║  ██║░░██╗  ██╔═██╗░  ░╚═══██╗
// ██║░░░░░  ██║░░██║  ╚█████╔╝  ██║░╚██╗  ██████╔╝
// ╚═╝░░░░░  ╚═╝░░╚═╝  ░╚════╝░  ╚═╝░░╚═╝  ╚═════╝░

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

import "../Handler.sol";
import "../Market.sol";
import "../ControlCenter.sol";

contract AccessPacks is ERC1155PresetMinterPauser {

  ControlCenter internal controlCenter;
  string public constant HANDLER = "HANDLER";
  string public constant MARKET = "MARKET";

  uint public currentTokenId;

  struct AccessRewards {
    string uri;
    uint supply;
  }

  mapping(uint => AccessRewards) public accessRewards;

  constructor(address _controlCenter) ERC1155PresetMinterPauser("") {
    controlCenter = ControlCenter(_controlCenter);
  }

  function createPackAndList(
    string calldata _packURI,
    string[] calldata _rewardURIs,
    uint[] calldata _rewardSupplies,
    address _saleCurrency,
    uint _salePrice
  ) external {

    require(_rewardURIs.length == _rewardSupplies.length, "Must specify equal number of URIs and supplies.");

    // Get tokenIds
    uint[] memory rewardIds = new uint[](_rewardURIs.length);
    
    for(uint i = 0; i < _rewardURIs.length; i++) {
      rewardIds[i] = currentTokenId;
      currentTokenId++;
    }

    // Mint reward tokens to `msg.sender`
    mintBatch(msg.sender, rewardIds, _rewardSupplies, "");

    // Call Handler to create packs with rewards.
    (uint packTokenId, uint packSupply) = handler().createPack(_packURI, address(this), rewardIds, _rewardSupplies);

    // Set on sale in Market.
    market().listPacks(packTokenId, _saleCurrency, _salePrice, packSupply);
  }

  function handler() internal view returns (Handler) {
    return Handler(controlCenter.getModule(HANDLER));
  }

  function market() internal view returns (Market) {
    return Market(controlCenter.getModule(MARKET));
  }
}