type function Not(t: type): type
	return types.negationof(t)
end

export type Reason = Not<nil>

return {}
