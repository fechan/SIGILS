import { MissingPeripheralBadge } from "./MissingPeripheralBadge";
import { useStore } from "zustand";
import { connectedPeriphsStore } from "../stores/connectedPeriphs";
import { PeriphId } from "@server/types/core-types";
import { useFactoryStore } from "../stores/factory";

interface MissingPeriphsProps {
  onDeletePeriph: (periphId: PeriphId) => void,
};

export function MissingPeriphs({ onDeletePeriph }: MissingPeriphsProps) {
  const factory = useFactoryStore();
  const { getMissing } = useStore(connectedPeriphsStore);
  const missingPeriphs = getMissing(factory.getPeripheralNames());

  return (
    <>
      {missingPeriphs.size > 0 && <div className="border p-3 border-2 rounded mcui-window mb-3">
        <header>
          <h2>Missing peripherals</h2>
          <span className="text-sm">Click to remove</span>
        </header>

        <ul>
          {
            Array.from(missingPeriphs).map(periphId => 
              <li
                key={periphId}
                onClick={ () => onDeletePeriph(periphId) }
                className="w-full mt-2"
              >
                <MissingPeripheralBadge periphId={periphId}/>
              </li>
            )
          }
        </ul>
      </div>}
    </>
  );
}