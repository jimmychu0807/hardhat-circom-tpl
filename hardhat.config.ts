import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "hardhat-circom";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  circom: {
    inputBasePath: "./circuits",
    outputBasePath: "./circuits/artifacts",
    // More ptau files at:
    //   https://github.com/iden3/snarkjs?tab=readme-ov-file#7-prepare-phase-2
    ptau: "https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_15.ptau",
    circuits: [{
      name: "lib",
      protocol: "plonk",
    }]
  }
};

export default config;
