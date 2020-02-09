
-- Here belong foul words which belong neither in names nor in chat.
anticurse.foul = {
  {word="s+e+x+", white={
		"whats", "exact", "exist", "xd", "except", "its", "exha", "exp", "extra", "thats",
		"extrem", "is", "was", "excit", "mass", "exodus", "names", "exclud", "else",
		"house", "example", "exchange", "please", "excuse", "course", "extend", "ones",
		"excellent", "exotic", "extensive",
	}},

	"h+y+m+e+n+",

	"s+%d+x+",
  
  {word="b+i*t+c+h+", white={"cheap", "doubt", "check", "childish", "chaotic"}},

  {word="c+u+n+t+", white={"truck"}},
  "c+v+n+t+",
	{word="t+w+a+t+", white={"water", "watch", "just", "wait"}},
  
  -- It's generally pretty easy to check for this naughty word.
  {word="f+u+c*k+", white={"keep", "know", "could"}},
  {word="f+u+c+k*", white={"can", "claim", "come", "came", "uclid", "could", "custom"}},

	"f+u+q+",
	"f+v+q+",
	"f+o+q+",
	"f+y+c+k+",
  "f+v+c*k+",
	"f+o+c+k+",
  "f+v+c+k*",
  "f+u*c+k+i+n+g+",
  "m+o+t+h+e+r+f+u*c+k+e+r+",
  "m+o*t+h+e*r+f+",
  "f+u*c+k+e+r+",
  "f+c+k+",
	"p+h+u*c*k+",

	{word="f+k+y+", white={
		"afk",
		"yet",
	}},

	{word="f+k+u+", white={"afk"}},
	"f+a+c*k+u",
	"f+a+c*k+y",
	"f+%d+c+k+",
	"n+i+g+e+r+",
  
  "b+l+o*w+j+o*b+",
	"s+h+t+h+o+l+e+",

  -- This word needs a big whitelist.
  {word="a+ss+", white={
    "glass", "brass", "grass", "vassal", "passion", "pass", "mass", "gass",
		"embarass", "class", "canvass", "assur", "assum", "associa", "assis+t",
    "assim+il", "assign", "assess", "assert", "assent", "potassium", "lass",
		"tassel", "bass", "assem", "sass", "assort", "assail", "quass", "assault",
    "morass", "bias", "nass", "vass", "dass", "as+as+in", "assauge", "assay",
		"secur", "asset", "sever", "assid", "assib", "soil", "assyria", "cass",
    "chass", "crass", "rass", "wassal", "hass", "ias", "sou", "was", "st",
		"spawn", "shock", "some", "shop", "so", "shield", "sin", "sac", "jas",
		"super", "supper", "shrub", "soon", "sil", "spr", "small", "scary", "slow",
		"speedy", "she", "simple", "sleep", "sick", "settle", "stress", "stand",
		"snow", "such", "yass", "fass", "dass", "kasse", "casse", "estas", "school",
		"sarc", "areas", "seem",
  }},

	"d+u+m+b+a+s+",
	"s+u+x+",
	"d+i+x+",
	{word="h+o+m+o+", white={"homogeneous"}},
	{word="t+i+t+s+", white={
		"wait", "got", "petits", "itsa", "itsnext", "itsnot", "test",
		"mt", "at", "itsin", "itsat", "itsjust", "havent", "itsonly",
	}},

	{word="b+oo+b+", white={"booby", "boo+boo+"}},

  "a+ss+e*h+o+l+e+",
  {word="a+h+o+l+e+s+", white={"sur", "inahole"}},

  {word="s+p+e*r+m+", white={
		"permanent", "permit", "was", "minute", "his", "permis+ion", "plants", "mese",
		"days", "month", "permafrost",
	}},
  {word="s+e+m+e+n+", white={
		"basement", "advertisement", "musement", "advisement", "mention", "now",
	}},

  -- Is it necessary to ban this word?
  --"s+e+e+d+",

  "v+a*g+i*n+a*",
  "v+a*j+i*n+a*",

  {word="p+e+n+i+s+", white={
		"happen", "sharpen", "dampen", "aspen", "shapen", "open", "pigpen",
	}},

  {word="b+r+e+a*s+t+", white={"brea*stplate", "noob", "rest"}},
  {word="d+i*c+k+", white={"dickens"}},
	{word="d+i+k+", white={"and", "know", "should", "kill", "would", "keep", "medikit"}},
  
  --"p+e+r+v+e+r+t+",
  
	"s+h+x+t+",
	{word="s+c+h+i*t+", white={"test", "the"}},
  {word="s+h+i+t+", white={
		"spanish", "then", "cash", "finish", "hit+ing", "was", "accomplish", "push",
		"wish", "bugs", "has", "trash", "crash", "his", "stash", "gosh", "does",
		"says", "too", "bombs", "mobs", "rush", "bush", "unless", "yesh", "the", "there",
		"smash", "english", "ar+ows", "dash", "ithink",
	}},

	"s+c+h+i+t+",
  {word="p+oo+p+", white={"nincompoop"}},
  "l+e+s+b+i+a+n+",
  {word="k+i+k+e+", white={"keep", "key", "kennst", "ski"}},
  {word="b+u+tt+", white={
		"rebutt", "button", "butter", "butting", "butte",
	}},

  {word="a+r+s+e+", white={
		"darsela", "similar", "parse", "setup", "hoarse", "sparse", "rehearse",
		"arsenal", "far", "war", "scarse", "dear", "self", "seem", "bar", "bear",
		"shears", "semilla", "carser", "server", "quedarse", "near", "sea", "coarse",
		"charset", "juntarse",
	}},

	{word="f+a+g+o+t+", white={"gotcha"}},
  {word="g+a+y+", white={"gayety", "gayeties", "yak", "ing", "yack"}},
  
  {word="p+u+s+y+", white={"pussycat", "pussyfoot"}},
  "p+ss+y+",
  
  {word="c+o+c+k+", white={"peacock", "cockney", "cockroach"}},
  {word="w+h+o+r+e+", white={"reach", "read", "really"}},
  
  {word="c+u+m+", white={
		"accumulat", "acumen", "circum", "cucumber", "cumber", "cumulat",
		"document", "ecumeni", "encumber", "encumbranc", "incumb", "locum", "scum",
		"succumb", "mach", "documen",
	}},
  {word="c+v+m+", white={"mach"}},

	-- Spanish.
	{word="p+u+t+o+s*", white={"input"}},
	{word="p+u+t+a+s*", white={
		"reputation",
	}},

	-- German.
	"h+u+r+e+n+s+o+h+n+", -- Son of a bitch/daughter of a whore.
	"s+c+h+w+u+c+h+t+e+l+" -- Gay.
}

-- Here belong curse words which belong neither in names nor in chat.
anticurse.curse = {
  {word="d+a+m+n+", white={"and", "not"}},
	"d+%d+m+n+",
  "d+a+m+n+i+t+",
  {word="d+a+n+m+i+t+", white={"dann"}},
	"d+a+mm+i+t+", -- With 2 m's, avoids interfering with German word.

	"g+o+d+a+m+i+t+",

  {word="h+e+ll+", white={
		"h+e+ll+p", "h+e+ll+o", "hell+e", "hell+a", "shell", "hell+uo", "hellen",
		"helleb", "hel+cat", "chell", "thel+",
	}},

  {word="h+a+d+e+s+", white={"desert", "shades", "design", "witha"}},

  -- Banned b/c 99/100, it's used to insult.
  {word="j+e+w+", white={"jewel"}},
}

-- Here belong words which shall not be used in names. (Chat is ok.)
anticurse.impersonate = {
  "a+d+m+i+n+",
  "a+b+b+a+",
  "o+w+n+e+r+",
  "s+e+r+v+e+r+",
  "m+o+d+e+r+a+t+o+r+",
  "g+o+d+",
  "h+i+t+l+e+r+",
  "a+d+o+l+f+",
  "m+u+s+t+e+s+t+",
  "s+i+n+g+l+e+p+l+a+y+e+r+",
}
