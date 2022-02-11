from manticore.ethereum import ManticoreEVM, ABI
from manticore.core.smtlib import Operators, Z3Solver
from manticore.utils import config
from manticore.core.plugin import Plugin

m = ManticoreEVM()

# Disable the gas tracking
consts_evm = config.get_group("evm")
consts_evm.oog = "ignore"

# Increase the solver timeout
config.get_group("smt").defaultunsat = False
config.get_group("smt").timeout = 3600

ETHER = 10 ** 18

deployer = m.create_account(balance=100 * ETHER, name="deployer")
user = m.create_account(balance=100 * ETHER, name="user")
attacker = m.create_account(balance=100 * ETHER, name="attacker")

print(f'[+] Create user wallet. deployer: {hex(deployer.address)}, user: {hex(user.address)}, attacker: {hex(attacker.address)}')

contract = m.solidity_create_contract('./Test.sol', contract_name='Test', owner=user)
print(f'[+] Deploy contract. address: {hex(contract.address)}')

x = m.make_symbolic_value()
y = m.make_symbolic_value()
z = m.make_symbolic_value()

print(f'[+] Call contract functions.')
# outline the transactions

contract.set(x, y, z, caller=attacker, value=1*ETHER)

m.get_balance(contract.address)

contract.take(caller=attacker)

m.get_balance(contract.address)

# Let seth know we are not sending more transactions
m.finalize(only_alive_states=True)

state_found = False
for state in m.ready_states:
    balance_before = state.platform.transactions[2].return_data
    balance_before = ABI.deserialize("uint", balance_before)

    balance_after = state.platform.transactions[-1].return_data
    balance_after = ABI.deserialize("uint", balance_after)

    # Check if it is possible to have balance_after > balance_before
    condition = Operators.UGT(balance_before, balance_after)
    if m.generate_testcase(state, name="State", only_if=condition):
        print("State found. see {}".format(m.workspace))
        state_found = True

if not state_found:
    print("[-] No state found")
