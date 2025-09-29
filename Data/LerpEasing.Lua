return 
{
	["Linear"] = 
	{
		["In"] = function(t)
			return t
		end,
		["Out"] = function(t)
			return t
		end,
		["InOut"] = function(t)
			return t
		end
	},
	["Quad"] = 
	{
		["In"] = function(t)
			return math.pow(t, 2)
		end,
		
		["Out"] = function(t)
			return t * (2 - t)
		end,
		
		["InOut"] = function(t)
			if t < 0.5 then
				return 2 * math.pow(t, 2)
			else
				return -1 + (4 - 2 * t) * t
			end
		end,
	},
	["Cubic"] = 
	{
		["In"] = function(t)
			return math.pow(t, 3)
		end,
		
		["Out"] = function(t)
			t -= 1
			
			return math.pow(t, 3) + 1
		end,
		
		["InOut"] = function(t)
			if t < 0.5 then
				return 4 * math.pow(t, 3)
			else
				t -=1
				return (math.pow(t, 3) * 4) + 1
			end
		end,
	},
	
	["Quart"] = 
	{
		["In"] = function(t)
			return math.pow(t, 4)
		end,	
		
		["Out"] = function(t)
			t -= 1
			return 1 - math.pow(t, 4)
		end,
		
		["InOut"] = function(t)
			if t < 0.5 then
				return 8 * math.pow(t, 4)
			else
				t -= 1
				return 1 - 8 * math.pow(t, 4)
			end
		end,
	},
	
	["Quint"] = 
	{
		["In"] = function(t)
			return math.pow(t, 5)
		end,
		
		["Out"] = function(t)
			t -= 1
			return 1 + math.pow(t, 5)
		end,
		
		["InOut"] = function(t)
			if t < 0.5 then
				return 16 * math.pow(t, 5)
			else
				t -= 1
				return 1 + 16 * math.pow(t, 5)
			end
		end,
	},
	
	["Sine"] = 
	{
		["In"] = function(t)
			return 1 - math.cos((t * math.pi) / 2)
		end,
		
		["Out"] = function(t)
			return math.sin((t * math.pi) / 2)
		end,
		
		["InOut"] = function(t)
			return -(math.cos(math.pi * t) - 1) / 2
		end,
	},
	
	["Exponential"] = 
	{
		["In"] = function(t)
			if t == 1 then
				return 1
			end
			
			return math.pow(2, 10 * (t - 1))
		end,
		
		["Out"] = function(t)
			if t == 0 then
				return 0
			end
			
			return 1 - math.pow(2, -10 * t)
		end,
		
		["InOut"] = function(t)
			if t == 0 then
				return 0
			end
			
			if t == 1 then
				return 1
			end
			
			if t < 0.5 then
				return math.pow(2, 20 * t - 10) / 2
			else
				return (2 - math.pow(2, -20 * t + 10)) / 2
			end
		end,
	},
	
	["Circular"] = 
	{
		["In"] = function(t)
			return 1 - math.sqrt(1 - math.pow(t, 2))
		end,
		
		["Out"] = function(t)
			t -= 1
			return math.sqrt(1 - math.pow(t, 2))
		end,
		
		["InOut"] = function(t)
			if t < 0.5 then
				return (1 - math.sqrt(1 - 4 * math.pow(t, 2))) / 2
			else
				t = t * 2 - 1
				return (math.sqrt(1 - math.pow(t, 2) + 1)) / 2
			end
		end,
	}
		
}
