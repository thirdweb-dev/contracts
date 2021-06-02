const packURIs = [
  'https://siasky.net/AADTWsStZLziMMaJChRYxAOxCZ7rscocx7GfwvLx309bag',
  'https://siasky.net/_BE4UzjYVtOu36HVwKWumeXmQgUUvUKLWZPuDRuzeIpl0w',
  'https://siasky.net/fALDtj5c1KqiUQvi6sawxEMkLjYYmOYrmLBlKUMqCY4wNg',
  'https://siasky.net/fALS84HucF6A5bsF-I2GNa75oio4rtr3vAM7WCn7PlO4Zg',
  'https://siasky.net/_AyTnOQNbgenuggWEXSDgahmlXDCqWTyLdFO54ME8Ogobw',
  'https://siasky.net/PAA_gi468BhdLw9XpLlNXQ26kS3srsagR-hA01kE7kWk-Q',
  'https://siasky.net/_B2027-GPaZI_nuSWgMTZthFfkO35zEKM-kUE_cPZ98-oQ',
  'https://siasky.net/_AYMLkCbLOaGL1woCX3yuoMKEtYu4z8crVkGHpABGOnDOA',
  'https://siasky.net/_BHcX3y5t3wlTafs_dwEkXtoa1vnVk6T1ZobX1g5IC3Aig',
  'https://siasky.net/3AFRWgeS0AhWFgvWRyHvuW3Avj8Vm2R3xD_aM3B5YnYvpw',
  'https://siasky.net/_BH5n9KrDUH2uhhpXDsSUjB-n2zE7cy18uL0MNoiBLfHoA',
  'https://siasky.net/_AgIymYQ7HXuer-cFWrLhT5hfYmnsXeSzNshW1JNJOmRZw',
]

const rewardURIs = [
  'https://siasky.net/IABmw8Ary3P-4zc9qFp6urgSW-DmolTva9s_3HIiVsDJhw',
  'https://siasky.net/KACgVMqI34PP1xmVZSGmOEhWH8hGY2U2oN9xqIThh4_Y1A',
  'https://siasky.net/KADzAKkdCqWJXVAjhVxHvRxabCVe3hlVASZVnSm732guuA',
  'https://siasky.net/KADVgLkIe2QjRqwl_kM3hAzTlSG01_R4-9AfAoYLdCW-lA',
  'https://siasky.net/IADtjJNzA5kBcieZPIWpu3nStFd3PU8iwYN62Ed2uQJ27Q'
]

const currencyAddresses = [
//   '0x49e7f00ee5652523fAdE13674100c8518d7DA8b6', // ERC 20 token (`PackCoin`)
  '0x0000000000000000000000000000000000000000' // Zero address == ETH (on the subgraph)
]

module.exports = {
  packURIs,
  rewardURIs,
  currencyAddresses
}