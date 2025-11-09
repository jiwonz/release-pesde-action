local tableUtil = {}

function tableUtil.entries<K, V>(
    t: { [K]: V }
): { { key: K, value: V } }
    local entries = {}

    for key, value in t do
        table.insert(
            entries,
            {
                key = key;
                value = value;
            }
        )
    end

    return entries
end

function tableUtil.fromEntries<K, V>(
    entries: { { key: K, value: V } }
): { [K]: V }
    local table: { [K]: V } = {}

    for _, entry in entries do
        table[entry.key] = entry.value
    end

    return table
end

function tableUtil.map<T, M>(t: { T }, f: (T, number, { T }) -> M): { M }
	local newT = table.create(#t)
	for k, v in t do
		newT[k] = f(v, k, t)
	end
	return newT
end

table.freeze(tableUtil)

return tableUtil
