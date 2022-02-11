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
print(f'[+] Created user wallet. deployer: {hex(deployer.address)}, user: {hex(user.address)}, attacker: {hex(attacker.address)}')

contract = m.solidity_create_contract('./Test.sol', contract_name='Test', owner=user)
print(f'[+] Deployed contract. address: {hex(contract.address)}')

print(f'[+] Declaring symbolic variables.')
x = m.make_symbolic_value()
y = m.make_symbolic_value()
z = m.make_symbolic_value()

print(f'[+] Calling contract functions.')

# outline the transactions
contract.set(x, y, z, caller=attacker, value=1*ETHER)
contract.take(caller=attacker)

# Let seth know we are not sending more transactions
print(f'[+] Finalizing transactions.')
m.finalize(only_alive_states=True)

print(f'[+] Generating transactions traces.')
num_state_found = 0
for state in m.all_states:
    num_state_found += 1
    balance = state.platform.get_balance(int(user_account))
    print(state.solve_one(balance))

print(f"[+] {num_state_found} constraints test cases generated.")
print(f"[+] Global coverage: {contract.address:x} - {m.global_coverage(contract)}")
print(f'[+] Results in workspace: {m.workspace}')
