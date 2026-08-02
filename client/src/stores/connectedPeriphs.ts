import { PeriphId } from '@server/types/core-types';
import { createStore } from 'zustand/vanilla';

// TODO: this might become a core type
export type PeriphMap = {[periphName: string]: number};

export interface ConnectedPeriphsStore {
  periphs: PeriphMap,
  setPeriphs: (periphs: PeriphMap) => void,
  getMissing: (periphsInFactory: Set<PeriphId>) => Set<PeriphId>,
  getAvailable: (periphsInFactory: Set<PeriphId>) => Set<PeriphId>,
};

export function createConnectedPeriphsStore() {
  return createStore<ConnectedPeriphsStore>()(
    (set, get) => ({
      periphs: {},
      setPeriphs: (periphs) => set({periphs}),
      getMissing: (periphsInFactory) => getMissing(get().periphs, periphsInFactory),
      getAvailable: (periphsInFactory) => getAvailable(get().periphs, periphsInFactory),
    })
  );
}

function getMissing(connected: PeriphMap, periphsInFactory: Set<PeriphId>) {
  const missing = new Set<PeriphId>();

  for (const factoryPeriph of periphsInFactory) {
    if (!(factoryPeriph in connected)) {
      missing.add(factoryPeriph);
    }
  }

  return missing;
}

function getAvailable(connected: PeriphMap, periphsInFactory: Set<PeriphId>) {
  const available = new Set<PeriphId>();

  for (const connectedPeriph of Object.keys(connected)) {
    if (!periphsInFactory.has(connectedPeriph)) {
      available.add(connectedPeriph);
    }
  }

  return available;
}