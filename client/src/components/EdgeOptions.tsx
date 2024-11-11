import { Pipe, PipeMode } from "@server/types/core-types";
import { useState } from "react";
import { SendMessage } from "react-use-websocket";
import { Edge, useOnSelectionChange, useStoreApi } from "reactflow";
import { GraphUpdateCallbacks } from "../GraphUpdateCallbacks";
import { useFactoryStore } from "../stores/factory";
import { FilterSyntax } from "./FilterSyntax";

interface EdgeOptionsProps {
  sendMessage: SendMessage,
};

export function EdgeOptions({ sendMessage }: EdgeOptionsProps) {
  const [ selectedEdges, setSelectedEdges ] = useState([] as Edge[]);

  const pipes = useFactoryStore(state => state.factory.pipes);
  const groups = useFactoryStore(state => state.factory.groups);

  const [ nickname, setNickname ] = useState("");
  const [ filter, setFilter ] = useState("");
  const [ isFluid, setIsFluid ] = useState(false);
  const [ mode, setMode ] = useState(undefined as string | undefined);

  useOnSelectionChange({
    onChange: ({ edges }) => {
      setSelectedEdges(edges);
      setFilter(edges.length === 1 ? (pipes[edges[0].id].filter || "") : "...");
      setNickname(edges.length === 1 ? (pipes[edges[0].id].nickname || "") : "...");
      setMode(edges.length === 1 ? pipes[edges[0].id].mode : "...");
      setIsFluid(edges.length > 0 && groups[pipes[edges[0].id].from].fluid === true);
    }
  });

  function onCommit() {
    const edits: Partial<Pipe> = {};
    let changes = false;

    if (nickname !== "...") {
      edits.nickname = nickname;
      changes = true;
    }
    
    if (filter !== "...") {
      edits.filter = filter;
      changes = true;
    }

    if (mode && mode !== "...") {
      edits.mode = mode as PipeMode;
      changes = true;
    }

    if (changes) {
      for (let edge of selectedEdges) {
        GraphUpdateCallbacks.onPipeUpdate(edge.id, edits, sendMessage)
      }
    }
  }

  const store = useStoreApi();
  const { addSelectedEdges } = store.getState();
  function onCancel() {
    addSelectedEdges([]);
  }

  return (
    <>
      {selectedEdges.length > 0 && <div className="border rounded p-3 border-2 mcui-window">
        <div className="mb-3 flex justify-between items-center">
          Editing { selectedEdges?.length || 'no' } pipes
          <button
            className="mcui-button w-8 h-8"
            onClick={ onCancel }
          >
            ×
          </button>
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
            onClick={ () => GraphUpdateCallbacks.onEdgesDelete(selectedEdges, sendMessage) }
          >
            Delete
          </button>
          <button
            className="mcui-button bg-green-800 w-32 h-10"
            onClick={ onCommit }
          >
            Update
          </button>
        </div>
      </div>}
    </>
  );
}