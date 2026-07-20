import { Group } from "@server/types/core-types";
import { useState } from "react";
import { Node, useOnSelectionChange, useStoreApi } from "reactflow";
import { GraphUpdateCallbacks } from "../GraphUpdateCallbacks";
import { useFactoryStore } from "../stores/factory";
import { Controller } from "../Controller";

interface GroupOptionsProps {
  onGroupEdit: Controller['editGroups'],
};

export function GroupOptions({ onGroupEdit }: GroupOptionsProps) {
  const [ selectedGroups, setSelectedGroups ] = useState([] as Node[]);

  const groups = useFactoryStore(state => state.factory.groups);

  const [ nickname, setNickname ] = useState("");

  useOnSelectionChange({
    onChange: ({ nodes }) => {
      const selectedNodeTypes = new Set(nodes.map(node => node.type));
      if (selectedNodeTypes.size === 1 && selectedNodeTypes.has("slot-group")) {
        setSelectedGroups(nodes);
        setNickname(nodes.length === 1 ? (groups[nodes[0].id].nickname || "") : "...");
      } else {
        setSelectedGroups([]);
      }
    }
  });

  function onCommit() {
    const edits: Partial<Group> = {};
    let changes = false;

    if (nickname !== "...") {
      edits.nickname = nickname;
      changes = true;
    }

    if (changes) {
      onGroupEdit(selectedGroups.map(node => node.id), edits);
    }
  }
  
  const store = useStoreApi();
  const { addSelectedNodes } = store.getState();
  function onCancel() {
    addSelectedNodes([]);
  }

  return (
    <>
      {selectedGroups.length > 0 && <div className="border p-3 border-2 rounded mcui-window">
        <div className="mb-3 flex justify-between items-center">
          Editing { selectedGroups?.length || 'no' } groups
          <button
            className="mcui-button w-8 h-8"
            onClick={ onCancel }
          >
            ×
          </button>
        </div>

        <div className="mb-3 flex flex-col">
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

        <div className="text-right box-border">
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