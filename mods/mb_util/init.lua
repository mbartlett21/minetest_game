-- based on http://lua-users.org/files/wiki_insecure/users/rici/lazysort.lua
-- see https://lua-users.org/wiki/LazySort

local table = table

table.lazysort_threshold = 20

local LazySort = {}

function LazySort:view_tree()
    return self:_lazy_getter ''
end

local lazy_meta = {
    __newindex = function(self, k, v)
        if type(k) ~= 'number' then
            rawset(self, k, v)
        else
            error('can\'t set numeric key of lazily sorted table')
        end
    end,
    __index = function(self, k)
        if type(k) ~= 'number' then
            if k == 'lazysort_threshold' then
                return table.lazysort_threshold
            end
            return LazySort[k]
        end

        return self:_lazy_getter(k)
    end,
}

-- Incremental quicksort, hopefully showing that quicksort
-- fundamentally uses a binary tree as an intermediate
-- (but deforested) data structure.
--
-- This implementation is lazy; if you ask for element
-- i of an array, it only sorts the array as much as
-- necessary to produce the element at i. The intermediate
-- result is maintained by the use of closures, rather
-- than explicitly in a binary tree; at each recursion
-- we create a new closure to represent the state of
-- the computation at that segment of the tree.
--
-- The "binary tree" is always complete; that is, each
-- element in the tree is either a Leaf, representing a
-- non-empty unsorted range of the vector, or a Node,
-- which has a left and right Tree and a non-empty
-- sorted range (in between left and right). In effect,
-- partioning is down on the way down, and merging on
-- the way up.

-- TODO: Create versions of sort3, partition and inssort
-- which take a sortation function; use this to efficiently
-- implement generalised sortation to match table.sort.
local function sort3(a, b, c)
    if a < b then
        if b < c then
            return a, b, c
        elseif a < c then -- b >= c
            return a, c, b
        else -- b >= c, a >= c
            return c, a, b
        end
    elseif a < c then -- a >= b
        return b, a, c
    elseif b < c then -- a >= b, a >= c
        return b, c, a
    else -- a >= b, a >= c, b >= c
        return c, b, a
    end
end
local function sort3f(lt, a, b, c)
    if lt(a, b) then
        if lt(b, c) then
            return a, b, c
        elseif lt(a, c) then -- b >= c
            return a, c, b
        else -- b >= c, a >= c
            return c, a, b
        end
    elseif lt(a, c) then -- a >= b
        return b, a, c
    elseif lt(b, c) then -- a >= b, a >= c
        return b, c, a
    else -- a >= b, a >= c, b >= c
        return c, b, a
    end
end


-- Based on Sedgwick, of course.
-- Requires that hi - lo >= 2
-- Rearranges v in place and returns start, fin such that:
--    v[i] <= v[start]  if lo    <= i < start
--    v[i] == v[start]  if start <= i < fin
--    v[i] >= v[start]  if fin   <= i < hi
--  and
--    lo < start < fin < hi

local math_floor = math.floor
local function partition(v, lo, hi)
    local mid = math_floor((lo + hi) / 2)
    local i, j = lo, hi - 2
    v[lo], pivot, v[hi - 1] = sort3(v[lo], v[mid], v[hi - 1])
    v[mid], v[j] = v[j], pivot
    while true do
        repeat i = i + 1 until v[i] >= pivot
        repeat j = j - 1 until v[j] <= pivot
        if i <= j then
            v[i], v[j] = v[j], v[i]
        else
            v[i], v[hi - 2] = pivot, v[i]
            return j + 1, i + 1
        end
    end
end
local function partitionf(lt, v, lo, hi)
    local mid = math_floor((lo + hi) / 2)
    local i, j = lo, hi - 2
    v[lo], pivot, v[hi - 1] = sort3f(lt, v[lo], v[mid], v[hi - 1])
    v[mid], v[j] = v[j], pivot
    while true do
        repeat i = i + 1 until not lt(v[i], pivot) -- >=
        repeat j = j - 1 until lt(v[j], pivot) or v[j] == pivot -- <=
        if i <= j then
            v[i], v[j] = v[j], v[i]
        else
            v[i], v[hi - 2] = pivot, v[i]
            return j + 1, i + 1
        end
    end
end

-- Insertion sort, used for small ranges
-- Sorts elements [lo, hi) of v, in place.
-- Returns nil, hi, lo (to be compatible with partialsort)
local function inssort(v, lo, hi)
    for i = lo + 1, hi - 1 do
        local elt = v[i]
        if elt < v[lo] then
            for j = i - 1, lo, -1 do
                v[j + 1] = v[j]
            end
            v[lo] = elt
        else
            local j = i - 1
            while elt < v[j] do
                v[j+1] = v[j]
                j = j - 1
            end
            v[j+1] = elt
        end
    end
    return nil, hi, lo
end
local function inssortf(lt, v, lo, hi)
    for i = lo + 1, hi - 1 do
        local elt = v[i]
        if lt(elt, v[lo]) then
            for j = i - 1, lo, -1 do
                v[j + 1] = v[j]
            end
            v[lo] = elt
        else
            local j = i - 1
            while lt(elt, v[j]) do
                v[j+1] = v[j]
                j = j - 1
            end
            v[j+1] = elt
        end
    end
    return nil, hi, lo
end


-- [[ Tree viewing
local function prep(s)
  return '+' .. ('-'):rep(#s - 1)
end

local function ishow(i)
  return i:gsub('[|+]%s+$', prep)
end
-- ]]

-- lazysort returns an accesor function of one parameter:
--
--   getter = lazysort(v, lo, hi)
--
-- such that:
--   val = getter(i)
-- returns the value with which would have index i in the
-- sorted vector v, in the range [lo, hi) which defaults
-- to [1, #v + 1)
-- 
-- After a call to getter(i), it is guaranteed that
--   v[j] <= v[i] for lo <= j < i
--   v[i] <= v[j] for i <= j < hi
-- Moreover, any previous such guarantees remain in force (i.e.
-- the vector is successively more sorted).
-- 
-- For example, to compute the mean of each quintile in a vector,
-- one could use the following:
--
-- function quintile_means(v)
--   local getter = lazysort(v)
--   local retval = {}
--   local start = 1
--   for i = 1, 5 do
--     local fin = math.ceil((#v * i) / 5)
--     local sum = getter(fin) 
--     -- equivalent to: sum = sorted_v[fin]
--     -- v is now partitioned such that the i'th quintile
--     -- is in [start, fin]
--     for j = fin-1, start, - 1 do sum = sum + v[j] end
--     retval[i] = sum / (fin - start + 1)
--     -- Get ready for the next iteration
--     start = fin + 1
--   end
--   return retval
-- end
--
-- Incompletely sorted ranges of the tree are represented by closures
-- whose interface is:
--  function(i, lo, hi) ==> closure, lo', hi'
-- where i is in the range [lo, hi);
-- 
-- One such function is partialsort, defined below.
--
-- On return:
--   The vector is sorted in ranges: [lo, lo') and [hi, hi')
-- and
--   The closure obeys the same interface, and can be
--   called with (i, lo', hi') where lo' <= i < hi'
--   in order to continue the sort.
-- If a closure completely sorts its range, it returns
-- nil, hi, lo: while it is true that nil is not strictly
-- speaking a closure, the above rule does not allow it to
-- be called, since there is no qualifying value of i.

local function lazysort(v, lo, hi, lt)
    lo = lo or 1
    hi = (hi or #v) + 1

    local threshold

    local function partialsort(i, lo, hi)
        -- [[ Tree viewing
        if type(i)=='string' then
            return print(('%sLeaf [%d, %d) Unsorted'):format(ishow(i), lo, hi))
        end
        -- ]]
        -- if the segment is "small", just sort it
        if hi - lo < threshold then
            if lt then
                return inssortf(lt, v, lo, hi)
            else
                return inssort(v, lo, hi, lt)
            end
        end
        -- Make the new "node" (i.e. closure)
        -- Note that this is nothing more than the quicksort recursion:
        --   start, fin = partition(v, lo, hi);
        --   return quicksort(v, lo, start)
        --          ++ range(v, start, fin)
        --          ++ quicksort(v, fin, hi)
        -- Except that the append is done "in place" and the recursion
        -- is done "on demand"

        local start, fin
        if lt then
            start, fin = partitionf(lt, v, lo, hi)
        else
            start, fin = partition(v, lo, hi)
        end
        local left, right = partialsort, partialsort

        -- The main work of the closure is to merge sorted Nodes:
        local function self(i, lo, hi)
            -- [[ Tree viewing
            if type(i)=='string' then
                print(('%sNode [%d, %d)'):format(ishow(i), lo, hi))
                i = i:gsub('%+', ' ')
                left(i .. '| ', lo, start)
                print(('%s+-Sorted [%d, %d)'):format(i, start, fin))
                return right(i .. '+ ', fin, hi)
            end
            -- ]]
            if i < start then
                left, lo, start = left(i, lo, start)
                if not left then -- completely sorted
                    return right, fin, hi
                end
            elseif i >= fin then
                right, fin, hi = right(i, fin, hi)
                if not right then
                    return left, lo, start
                end
            end
            return self, lo, hi
        end
        -- Now we need to call the new closure to continue the sort
        return self(i, lo, hi)
    end

    -- The top-level lazy getter is the inverse of a Tree: it has
    -- one unsorted range sandwiched in between two sorted ranges.
    -- Initially the sorted ranges are empty (the only place where
    -- empty ranges are allowed) and the unsorted range is the whole
    -- vector.
    local middle = partialsort
    return function(tbl, i)
        threshold = tbl.lazysort_threshold or 20
        -- [[ Tree viewing
        if type(i) == 'string' then
            print(i .. 'Root')
            print(('%s+-Sorted [%d, %d)'):format(i, 1, lo))
            middle(i .. '| ', lo, hi)
            return print(('%s+-Sorted [%d, %d)'):format(i, hi, #v))
        end
        -- ]]
        if i >= lo and i < hi then
            middle, lo, hi = middle(i, lo, hi)
        end
        return v[i]
    end
end

-- Note: this does not modify the original table
-- table.sort (list [, lo, hi] [, comp])
function table.lazysort(t, a1, a2, a3) --> table
    local vec = {}
    for i, v in ipairs(t) do
        vec[i] = v
    end

    local lo, hi, lt

    if a3 or a2 then
        -- lo, hi [, comp]
        lo, hi, lt = a1, a2, a3
    else
        -- [comp]
        lt = a1
    end

    local getter = lazysort(vec, lo, hi, lt)
    return setmetatable({
        _lazy_getter = getter,
        _vec = vec
    }, lazy_meta)
end
