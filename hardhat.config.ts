import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "hardhat-circom";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  circom: {
    inputBasePath: "./circuits",
    outputBasePath: "./circuits/artifacts",
    ptau: "pot15_final.ptau",
    circuits: [{
      name: "lib",
      protocol: "plonk",
    }]
  }
};

export default config;
