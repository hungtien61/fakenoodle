class_name ChaosCards
extends RefCounted

const CARDS: Array[Dictionary] = [
	{
		"id": "swap_act",
		"title": "🎭 Hoán Đổi Diễn Xuất",
		"template": "{P1} và {P2} lập tức đổi phong cách nói cho nhau!",
		"targets": 2
	},
	{
		"id": "whisper",
		"title": "🤫 Nói Thì Thầm",
		"template": "Cấm nói to! Vòng này cả bàn chỉ được thì thầm vào tai người bên cạnh.",
		"targets": 0
	},
	{
		"id": "point_first",
		"title": "⚡ Chỉ Mặt Điểm Tên",
		"template": "{P1} phải là người mở miệng nói đầu tiên ở vòng này!",
		"targets": 1
	},
	{
		"id": "speedrun",
		"title": "⏱️ Bắn Tỉa 3 Giây",
		"template": "Đếm 3 - 2 - 1! Mỗi người chỉ có đúng 3 giây để nói. Quá giờ là mất lượt!",
		"targets": 0
	},
	{
		"id": "liar",
		"title": "🤥 Ngày Nói Dối",
		"template": "Tất cả mọi người PHẢI NÓI DỐI! Nói một manh mối SAI HOÀN TOÀN về từ khoá.",
		"targets": 0
	},
	{
		"id": "hot_seat",
		"title": "🔥 Ghế Nóng Ép Cung",
		"template": "Cả bàn tra khảo {P1}! Mỗi người hỏi 1 câu, {P1} chỉ được đáp ĐÚNG hoặc SAI.",
		"targets": 1
	},
	{
		"id": "tied_fate",
		"title": "⛓️ Cặp Đôi Đồng Mệnh",
		"template": "{P1} và {P2} chung số phận! Ai bị vote thì người kia cũng ăn trọn phiếu vote theo.",
		"targets": 2
	},
	{
		"id": "no_sound",
		"title": "🤐 Cấm Mở Miệng",
		"template": "Cấm phát ra tiếng! Vòng này chỉ được mấp máy môi (nhép miệng) để tả từ khoá.",
		"targets": 0
	},
	{
		"id": "stare_down",
		"title": "👁️ Nhìn Nhau Đắm Đuối",
		"template": "Khi nói, bạn PHẢI nhìn chằm chằm vào mắt người ngồi bên phải không được chớp!",
		"targets": 0
	},
	{
		"id": "switch_seats",
		"title": "🔀 Đổi Ghế Chạy Chỗ",
		"template": "Cả bàn đứng lên! Di chuyển sang bên PHẢI đúng 2 ghế rồi ngồi xuống.",
		"targets": 0
	},
	{
		"id": "echo",
		"title": "🦜 Tiếng Vọng (Bắt Chước)",
		"template": "Phải dùng TỪ CUỐI CÙNG của người vừa nói trước để mở đầu câu của bạn!",
		"targets": 0
	},
	{
		"id": "shield",
		"title": "🛡️ Khiên Miễn Tử",
		"template": "{P1} nhận được Khiên Vàng! Vòng này không ai được phép vote {P1}.",
		"targets": 1
	}
]

static func draw_card(player_list: Array, exclude_ids: Array = []) -> Dictionary:
	var available_cards: Array[Dictionary] = []
	for card in CARDS:
		if not card["id"] in exclude_ids:
			available_cards.append(card)
	
	if available_cards.is_empty():
		available_cards = CARDS.duplicate()
	
	var chosen: Dictionary = available_cards.pick_random().duplicate()
	
	var shuffled: Array = player_list.duplicate()
	shuffled.shuffle()
	
	var p1: String = "Người chơi 1"
	var p2: String = "Người chơi 2"
	
	if shuffled.size() > 0:
		p1 = str(shuffled[0])
	if shuffled.size() > 1:
		p2 = str(shuffled[1])
	else:
		p2 = p1
	
	var desc: String = chosen["template"]
	desc = desc.replace("{P1}", p1)
	desc = desc.replace("{P2}", p2)
	
	var p1_colored: String = "[b][color=#FFD700]" + p1 + "[/color][/b]"
	var p2_colored: String = "[b][color=#00E5FF]" + p2 + "[/color][/b]"
	var bb_desc: String = chosen["template"]
	bb_desc = bb_desc.replace("{P1}", p1_colored)
	bb_desc = bb_desc.replace("{P2}", p2_colored)
	bb_desc = "[center]" + bb_desc + "[/center]"
	
	return {
		"id": chosen["id"],
		"title": chosen["title"],
		"description": desc,
		"bbcode_description": bb_desc,
		"player_1": p1,
		"player_2": p2
	}
