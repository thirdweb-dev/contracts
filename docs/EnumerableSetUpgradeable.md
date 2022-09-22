# EnumerableSetUpgradeable







*Library for managing https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive types. Sets have the following properties: - Elements are added, removed, and checked for existence in constant time (O(1)). - Elements are enumerated in O(n). No guarantees are made on the ordering. ``` contract Example {     // Add the library methods     using EnumerableSet for EnumerableSet.AddressSet;     // Declare a set state variable     EnumerableSet.AddressSet private mySet; } ``` As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`) and `uint256` (`UintSet`) are supported. [WARNING] ====  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet. ====*



