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

contract = m.solidity_create_contract('src/test/mocks/WETH9.sol', contract_name='WETH9', owner=deployer, compile_args={
    "solc_remaps": "@openzeppelin=node_modules/@openzeppelin @chainlink=node_modules/@chainlink",
    "solc_args": "optimize optimize-runs=800 metadata-hash=none"
})
print(f'[+] Deployed contract. address: {hex(contract.address)}')

print(f'[+] Declaring symbolic variables.')
x = m.make_symbolic_value()
v = m.make_symbolic_value()

print(f'[+] Calling contract functions sequences.')

# contrainsts
m.constrain(x > 0)

# outline the transactions
m.transaction(caller=attacker, address=contract, value=v, data=m.make_symbolic_buffer(4+32*4))
contract.withdraw(x, caller=attacker)

print(f"[+] There are {m.count_all_states()} states. ({m.count_ready_states()} ready, {m.count_terminated_states()} terminated, {m.count_busy_states()} alive).")
m.take_snapshot()

print(f'[+] Generating symbolic conditional transactions traces.')
num_state_found = 0
for state in m.ready_states:
    # withdrawing more than deposited
    condition = x > v
    if m.generate_testcase(state, only_if=condition, name="constraint"):
        num_state_found += 1
print(f"[+] {num_state_found} constraints test cases generated.")

m.goto_snapshot()
m.take_snapshot()
print(f'[+] Finalizing transactions.')
m.finalize(only_alive_states=True)

m.goto_snapshot()
m.take_snapshot()
print(f"[+] Global coverage: {contract.address:x} - {m.global_coverage(contract)}%")
print(f'[+] Results in workspace: {m.workspace}')
