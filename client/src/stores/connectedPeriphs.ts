import { PeriphId, PeriphManifest } from '@server/types/core-types';
import { createStore } from 'zustand/vanilla';

export interface ConnectedPeriphsStore {
  periphs: PeriphManifest,
  setPeriphs: (periphs: PeriphManifest) => void,
  getMissing: (periphsInFactory: Set<PeriphId>) => Set<PeriphId>,
  getAvailable: (periphsInFactory: Set<PeriphId>) => Set<PeriphId>,
  isPeriphMissing: (periphId: PeriphId, periphsInFactory: Set<PeriphId>) => boolean,
};

export function createConnectedPeriphsStore() {
  return createStore<ConnectedPeriphsStore>()(
    (set, get) => ({
      periphs: {},
      setPeriphs: (periphs) => set({periphs}),
      getMissing: (periphsInFactory) => getMissing(get().periphs, periphsInFactory),
      getAvailable: (periphsInFactory) => getAvailable(get().periphs, periphsInFactory),
      isPeriphMissing: (periphId, periphsInFactory) => isPeriphMissing(periphId, get().periphs, periphsInFactory),
    })
  );
}

export const connectedPeriphsStore = createConnectedPeriphsStore();

function getMissing(connected: PeriphManifest, periphsInFactory: Set<PeriphId>) {
  const missing = new Set<PeriphId>();

  for (const factoryPeriph of periphsInFactory) {
    if (!(factoryPeriph in connected)) {
      missing.add(factoryPeriph);
    }
  }

  return missing;
}

function getAvailable(connected: PeriphManifest, periphsInFactory: Set<PeriphId>) {
  const available = new Set<PeriphId>();

  for (const connectedPeriph of Object.keys(connected)) {
    if (!periphsInFactory.has(connectedPeriph)) {
      available.add(connectedPeriph);
    }
  }

  return available;
}

function isPeriphMissing(periphId: PeriphId, connected: PeriphManifest, periphsInFactory: Set<PeriphId>) {
  const missing = getMissing(connected, periphsInFactory);
  return missing.has(periphId);
}