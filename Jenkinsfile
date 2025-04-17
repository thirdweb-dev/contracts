@Library('shared-library@feature/foundry') _

def pipelineConfig = [
  "JSpublicLibrary": "true",
  "pkgRepoName": "npmjs-org",
  "buildWith": "nodetrufflefoundry",
  "baseImageTag": "20.18.3-bullseye"
]

pipelinePackageRelease(pipelineConfig)