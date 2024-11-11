import { PipeAddReq } from "@server/types/messages";
import { Dispatch, SetStateAction, useState } from "react";
import { SendMessage } from "react-use-websocket";
import { Edge } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { FilterSyntax } from "./FilterSyntax";
import { useFactoryStore } from "../stores/factory";
import { PipeMode } from "@server/types/core-types";

export interface TempEdgeOptionsProps {
  sendMessage: SendMessage,
  tempEdge: (Edge | null),
  setTempEdge: Dispatch<SetStateAction<Edge | null>>,
  onCancel: () => void,
};

export function TempEdgeOptions({ tempEdge, setTempEdge, sendMessage, onCancel }: TempEdgeOptionsProps) {
  const [ nickname, setNickname ] = useState("");
  const [ filter, setFilter ] = useState("");
  const [ mode, setMode ] = useState("");

  const groups = useFactoryStore(state => state.factory.groups);

  const isFluid = tempEdge && groups[tempEdge.source].fluid;

  function onCommit() {
    if (!(tempEdge && tempEdge.source && tempEdge.target)) return;

    const reqId = uuidv4();
    const pipeAddReq: PipeAddReq = {
      type: "PipeAdd",
      reqId: reqId,
      pipe: {
        id: tempEdge.id,
        from: tempEdge.source,
        to: tempEdge.target,
      }
    };

    if (nickname !== "") pipeAddReq.pipe.nickname = nickname;
    if (filter !== "") pipeAddReq.pipe.filter = filter;
    if (mode !== "") pipeAddReq.pipe.mode = mode as PipeMode;

    setTempEdge(null);
    sendMessage(JSON.stringify(pipeAddReq));
  }

  return (
    <div className="overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 flex justify-center items-center w-full h-full md:inset-0 bg-black/70">
      <div className="border rounded p-3 border-2 mcui-window">
        <div className="mb-3">
          Creating a new pipe
        </div>

        <div className="flex flex-col mb-3">
          <label htmlFor="nickName" className="mb-1">Nickname</label>
          <input
            type="text"
            name="nickName"
            id="nickName"
            className="mcui-input p-1 ps-2"
            value={ nickname }
            onInput={ e => setNickname((e.target as HTMLInputElement).value) }
          />
        </div>

        <div className="flex flex-col mb-3">
          <label htmlFor="pipeFilter" className="mb-1">Item filter</label>
          <input
            type="text"
            name="pipeFilter"
            id="pipeFilter"
            className="mcui-input p-1 ps-2"
            value={ filter }
            onInput={ e => setFilter((e.target as HTMLInputElement).value) }
          />
          <FilterSyntax />
        </div>

        { !isFluid &&
          <div className="mb-5">
            <label htmlFor="mode" className="block mb-1">Mode</label>
            <select
              value={ mode }
              onChange={ e => setMode(e.target.value) }
              className="mcui-button p-2 w-full h-10"
            >
              <option value="natural">Natural (default)</option>
              <option value="spread">Spread</option>
            </select>
          </div>
        }

        <div className="text-right box-border">
          <button
            className="mcui-button bg-red-700 w-32 h-10 me-3"
            onClick={ onCancel }
          >
            Cancel
          </button>
          <button
            className="mcui-button bg-green-800 w-32 h-10"
            onClick={ onCommit }
          >
            Create Pipe
          </button>
        </div>
      </div>
    </div>
  );
}
