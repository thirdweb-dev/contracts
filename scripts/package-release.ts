import * as fs from "fs-extra";
import * as path from "path";

// Define the paths for the directories
const artifactsForgeDir = path.join(__dirname, "..", "artifacts_forge");
const contractsDir = path.join(__dirname, "..", "contracts");
const contractArtifactsDir = path.join(__dirname, "..", "contract_artifacts");

const specialCases: string[] = [
  "IRouterState.sol",
  "BaseRouter.sol",
  "ExtensionManager.sol",
  "MockContractPublisher.sol",
];

async function getAllSolidityFiles(dir: string): Promise<string[]> {
  const dirents = await fs.readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    dirents.map(dirent => {
      const res = path.join(dir, dirent.name);
      return dirent.isDirectory() ? getAllSolidityFiles(res) : res;
    }),
  );
  // Flatten the array and filter for .sol files
  return files
    .flat()
    .filter(file => file.endsWith(".sol"))
    .map(file => path.basename(file));
}

async function main() {
  // Create the contract_artifacts directory
  await fs.ensureDir(contractArtifactsDir);

  // Get all directories within artifacts_forge that match *.sol
  const artifactDirs = await fs.readdir(artifactsForgeDir);
  const validArtifactDirs = artifactDirs.filter(dir => dir.endsWith(".sol"));

  // Get all .sol filenames within contracts (recursively)
  const validContractFiles = await getAllSolidityFiles(contractsDir);

  // Check if directory-name matches any Solidity file name from contracts
  for (const artifactDir of validArtifactDirs) {
    // Removing the .sol extension from the directory name to match with file names
    const artifactName = path.basename(artifactDir, ".sol");

    if (validContractFiles.includes(artifactName + ".sol") || specialCases.includes(artifactName + ".sol")) {
      const sourcePath = path.join(artifactsForgeDir, artifactDir);
      const destinationPath = path.join(contractArtifactsDir, artifactDir);
      await fs.copy(sourcePath, destinationPath);
    }
  }

  console.log("Done copying matching directories.");
}

main().catch(error => {
  console.error("An error occurred:", error);
});
