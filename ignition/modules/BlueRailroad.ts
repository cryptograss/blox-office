import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Address } from 'viem';

const BlueRailroadModule = buildModule("BlueRailroad-V2", (m) => {
  const initialOwner = m.getParameter<Address>(
    "initialOwner"
  );

  const baseUri = m.getParameter(
    "baseUri",
    "https://cryptograss.live/token-metadata/"
  );

  const blueRailroad = m.contract("BlueRailroadV2", [
    "dingos",
    initialOwner,
    baseUri
  ]);

  return { blueRailroad };
});

export default BlueRailroadModule; 