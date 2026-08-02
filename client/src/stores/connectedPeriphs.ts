import { createStore } from 'zustand/vanilla';

// TODO: this might become a core type
export type PeriphMap = {[periphName: string]: number};

export interface ConnectedPeriphsStore {
  periphs: PeriphMap,
  setPeriphs: (periphs: PeriphMap) => void
};

export function createConnectedPeriphsStore() {
  return createStore<ConnectedPeriphsStore>()(
    (set) => ({
      periphs: {},
      setPeriphs: (periphs) => set({periphs}),
    })
  );
}