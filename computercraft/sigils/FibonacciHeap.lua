local setmetatable = setmetatable

-- node construction -----------------------------------------------------------

local node = {}

function node.new(v, o)
    local instance = {
        value = v,
        object = o,
        next = nil,
        prev = nil,
        child = nil,
        parent = nil,
        marked = false,
        degree = 0
    }
    setmetatable(instance, { __index = node })
    instance.next = instance
    instance.prev = instance
    return instance
end


local function printHeap(node, prefix, isTail)
    if not node then return end

    local tailSymbol = isTail and "└── " or "├── "
    print(prefix .. tailSymbol .. "Value: " .. tostring(node.value) .. ", Degree: " .. tostring(node.degree) .. ", Marked: " .. tostring(node.marked) .. " , Next: " .. tostring(node.next.value) .. " , Prev: " .. tostring(node.prev.value) )
    local child = node.child
    if child then
        local childPrefix = prefix .. (isTail and "    " or "│   ")
        local siblings = {}
        repeat
            table.insert(siblings, child)
            child = child.next
        until child == node.child

        for i, sibling in ipairs(siblings) do
            printHeap(sibling, childPrefix, i == #siblings)
        end
    end
end

local function merge(nodeA, nodeB)
    if (nodeA == nil) then return nodeB end
    if (nodeB == nil) then return nodeA end
    if (nodeA.value > nodeB.value ) then
        nodeA, nodeB = nodeB, nodeA
    end

    local an = nodeA.next
    local bp = nodeB.prev
    nodeA.next = nodeB
    nodeB.prev = nodeA
    an.prev = bp
    bp.next = an

    return nodeA
end

local function addChild(parent, child)
    child.prev = child
    child.next = child
    child.parent = parent
    parent.degree = parent.degree + 1
    parent.child = merge(parent.child, child)
end

local function unMarkAndUnParentAll(n)
    if n then
        local c = n
        repeat
            c.marked = false
            c.parent = nil
            c = c.next
        until c == n
    end
end

local function removeMinimum(n)

    unMarkAndUnParentAll(n.child)

    if n.next == n then
        n = n.child
    else
        n.next.prev = n.prev
        n.prev.next = n.next
        n = merge(n.next, n.child)
    end

    if not n then return nil end
    local trees = {}
    while true do
        local advanceN = true

        if trees[n.degree] then
            local t = trees[n.degree]
            if t == n then break end
            trees[n.degree] = nil

            if n.value < t.value then
                t.prev.next, t.next.prev = t.next, t.prev
                addChild(n, t)
                
            else
                n.prev.next, n.next.prev = n.next, n.prev
                addChild(t, n)
                n = t
            end

            advanceN = false
        else
            trees[n.degree] = n
        end

        if advanceN then
          n = n.next
        end
    end

    local min = n
    local start = n
    repeat
        if n.value < min.value then min = n end
        n = n.next
    until n == start
    return min
end

local function cut(heap, n)
    if n.next == n then
        if n.parent then
            n.parent.child = nil
        end
    else
        n.next.prev = n.prev
        n.prev.next = n.next
        if n.parent and n.parent.child == n then
            n.parent.child = n.next
        end
    end

    n.next = n
    n.prev = n
    n.marked = false
    n.parent = nil

    return merge(heap, n) 
end

local function decreaseKey(heap, n, value)
    if n.value < value then return heap end
    n.value = value

    if n.parent then
        if n.value < n.parent.value then
            heap = cut(heap, n)
            local parent = n.parent
            n.parent = nil

            while parent and parent.marked do
                heap = cut(heap, parent)
                n = parent
                parent = n.parent
                n.parent = nil
            end

            if parent and parent.parent then
                parent.marked = true
            end
        end
    else
        if heap and n.value < heap.value then
            heap = n
        end
    end

    return heap
end



-- fibonacciHeap construction -----------------------------------------------------------

local fibonacciHeap = {}

function fibonacciHeap.new()
    local instance = { 
        heap = nil
    }
    setmetatable(instance, { __index = fibonacciHeap })
    return instance
end

function fibonacciHeap:isEmpty()
    return self.heap == nil
end

function fibonacciHeap:getMinimum()
    return self.heap
end

function fibonacciHeap:pop()
    if not self.heap then return nil end
    local old = self.heap
    self.heap = removeMinimum(self.heap)
    return old
end

function fibonacciHeap:decreaseKey(n, value)
    self.heap = decreaseKey(self.heap, n, value)
end

function fibonacciHeap:insert(value, object)
    local ret = node.new(value, object)
    self.heap = merge(self.heap, ret)
    return ret
end

function fibonacciHeap:print()
    if not self.heap then
        print("The heap is empty.")
        return
    end
    print("Fibonacci Heap:")
    local start = self.heap
    local node = start
    repeat
        printHeap(node, "", node.next == start)
        node = node.next
    until node == start
end


return fibonacciHeap