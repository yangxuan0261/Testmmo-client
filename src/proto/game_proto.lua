local sparser = require "sprotoparser"

local game_proto = {}

local types = [[

.package {
	type 0 : integer
	session 1 : integer
}

.general {
	name 0 : string
	race 1 : string
	class 2 : string
	map 3 : string
}

.position {
	x 0 : integer
	y 1 : integer
	z 2 : integer
	o 3 : integer
}

.movement {
	pos 0 : position
}

.attribute {
	health 0 : integer
	level 1 : integer
	exp 2 : integer
	health_max 3 : integer
	strength 4 : integer
	stamina 5 : integer
	attack_power 6 : integer
}

.attribute_overview {
	level 0 : integer
}

.attribute_aoi {
	level 0 : integer
	health 1 : integer
	health_max 2 : integer
}

.character {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute
	movement 3 : movement
}

.character_agent {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute
	movement 3 : movement
}

.character_overview {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute_overview
}

.character_aoi {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute_aoi
	movement 3 : movement
}

.character_aoi_move {
	id 0 : integer
	movement 1 : movement
}

.character_aoi_attribute {
	id 0 : integer
	attribute 1 : attribute_aoi
}
]]

local c2s = [[
character_list 0 {
	response {
		character 0 : *character_overview(id)
	}
}

character_create 1 {
	request {
		character 0 : general
	}

	response {
		character 0 : character_overview
		errno 1 : integer
	}
}

character_pick 2 {
	request {
		id 0 : integer 
	}

	response {
		character 0 : character
		errno 1 : integer
	}
}

character_delete 3 {
    request {
        id 0 : integer 
    }

    response {
        num 0 : integer
    }
}

map_ready 100 {
    request {
    }
}

move 200 {
	request {
		pos 0 : position
	}
	response {
		pos 0 : position
	}
}

combat 400 {
	request {
		target 0 : integer
	}
	response {
		target 0 : integer
		damage 1 : integer
	}
}

test1 10100 {
    request {
        arg1 0 : integer
        arg2 1 : string
    }
    response {
        ret1 0 : integer
        ret2 1 : string
    }
}

gm 20100 {
    request {
        data 0 : string
    }
    response {
        func 0 : string
        data 1 : string
    }
}

]]

local s2c = [[
aoi_add 0 {
    request {
        character 0 : character_aoi
    }
    response {
        wantmore 0 : boolean
    }
}

aoi_remove 1 {
	request {
		character 0 : integer
	}
}

aoi_update_move 2 {
	request {
		character 0 : character_aoi_move
	}
	response {
        wantmore 0 : boolean
		myStr 1 : string
	}
}

aoi_update_attribute 3 {
	request {
		character 0 : character_aoi_attribute
	}
	response {
		wantmore 0 : boolean
	}
}

test2 4 {
    request {
        cat 0 : string
    }
    response {
        dog 0 : string
    }
}

user_info 20101 {
    request {
        data 0 : string
    }
}

user_chat 20102 {
    request {
        flag 0 : integer
        data 1 : string
    }
}


tips 20100 {
    request {
        content 0 : string
    }
}

]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
