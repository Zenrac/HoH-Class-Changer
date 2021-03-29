
namespace ClassChanger
{
	class ClassChangerMenuContent : ShopMenuContent
	{
		ScrollableWidget@ m_wList;
		Widget@ m_wTemplate;
		
		Sprite@ m_spriteGold;
		Sprite@ m_spriteOre;

		ClassChangerMenuContent(UnitPtr unit, SValue& params)
		{
			super();
		}
		
		void OnShow() override
		{
			@m_wList = cast<ScrollableWidget>(m_widget.GetWidgetById("list"));
			@m_wTemplate = m_widget.GetWidgetById("template");

			@m_spriteGold = m_def.GetSprite("gold");
			@m_spriteOre = m_def.GetSprite("ore");

			ReloadList();
		}

		string GetTitle() override
		{
			return Resources::GetString(".mod.classchanger.menu.title");
		}
		
		void ReloadList() override
		{
			m_wList.PauseScrolling();
			m_wList.ClearChildren();

			auto gm = cast<Campaign>(g_gameMode);
			auto record = GetLocalPlayerRecord();
			auto town = gm.m_townLocal;

			for (uint i = 0; i < g_classes.length(); i++)
			{
				auto customClass = g_classes[i];
				bool classUnlocked = false;
				bool requiredFlags = true;

				//Template Widget
				auto wNewClass = m_wTemplate.Clone();
				wNewClass.SetID(customClass.m_id + "-tab");
				wNewClass.m_visible = true;
				
				//Portrait Widget
				auto wPortrait = cast<PortraitWidget>(wNewClass.GetWidgetById("portrait"));
				if (wPortrait !is null)
					wPortrait.SetClass(customClass.m_id);
					wPortrait.SetDyes(record.colors);
					wPortrait.UpdatePortrait();

				//Name Widget
				auto wNameContainer = cast<RectWidget>(wNewClass.GetWidgetById("name-container"));
				if (wNameContainer !is null)
				{
					auto wName = cast<TextWidget>(wNameContainer.GetWidgetById("name"));
					if (wName !is null)
					{	
						auto className = customClass.m_name;
						//print(customClass.m_name);
						if (className != "")
							wName.SetText(className);
						else
							wName.SetText("Undefined Class");
						
					}
				}
				
				//Check Flags
				if (customClass.m_flags.length() > 0)
				{
					requiredFlags = false;
					for (uint j = 0; j < customClass.m_flags.length(); j++){
						auto flag = customClass.m_flags[j];
						auto parseFlag = flag.split(",");
						//print(customClass.m_name + " Class has requirements: " + flag);
						if(parseFlag[0] == "apothecary" 
						|| parseFlag[0] == "blacksmith" 
						|| parseFlag[0] == "chapel" 
						|| parseFlag[0] == "fountain" 
						|| parseFlag[0] == "generalstore" 
						|| parseFlag[0] == "guildhall" 
						|| parseFlag[0] == "magicshop" 
						|| parseFlag[0] == "oretrader" 
						|| parseFlag[0] == "tavern" 
						|| parseFlag[0] == "townhall" 
						|| parseFlag[0] == "treasury" )
						{
							//print(customClass.m_name + " needs level " + parseFlag[1] + " " + parseFlag[0]);
							requiredFlags = IsBuildingLevel(parseFlag[0], parseFlag[1]);
						}
						else if (parseFlag[0] == "dlc")
						{
							requiredFlags = Platform::HasDLC(parseFlag[1]);
						}
						else 
						{
							requiredFlags = IsFlagSet(flag);
						}
					}
				}
				
				//Unlock Class
				//print("Required flags met for " + customClass.m_name + ": " + requiredFlags);
				//print(customClass.m_name + "Class unlocked: " + IsFlagSet(customClass.m_id + "_unlocked"));
				
				int unlockCost = GetOrePrice(customClass.m_id);
				if (unlockCost == 0 || IsFlagSet(customClass.m_id + "_unlocked"))
					classUnlocked = true;
				
				auto wButtonUnlock = cast<ScalableSpriteButtonWidget>(wNewClass.GetWidgetById("button-unlock"));
				if (wButtonUnlock !is null)
				{
					
					wButtonUnlock.m_tooltipTitle = Resources::GetString(".mod.classchanger.menu.unlock");
					wButtonUnlock.m_tooltipText = Resources::GetString(".mod.classchanger.menu.unlock.desc");
					wButtonUnlock.AddTooltipSub(m_spriteOre, formatThousands(unlockCost));
					
					if (!Currency::CanAfford(0, unlockCost) || requiredFlags == false || classUnlocked == true)
						wButtonUnlock.m_enabled = false;
					else
						wButtonUnlock.m_func = "unlock " + customClass.m_id;
				}

				//Buy Class
				auto wButtonBuy = cast<ScalableSpriteButtonWidget>(wNewClass.GetWidgetById("button-buy"));
				if (wButtonBuy !is null)
				{
					int trainCost = GetPrice();
					wButtonBuy.m_tooltipTitle = Resources::GetString(".mod.classchanger.menu.buy");
					wButtonBuy.m_tooltipText = Resources::GetString(".mod.classchanger.menu.buy.desc");
					wButtonBuy.AddTooltipSub(m_spriteGold, formatThousands(trainCost));

					if (!Currency::CanAfford(trainCost) || classUnlocked == false)
						wButtonBuy.m_enabled = false;
					else
						wButtonBuy.m_func = "train " + customClass.m_id;
				}
			m_wList.AddChild(wNewClass);
			}
			
			m_wList.ResumeScrolling();
			m_shopMenu.DoLayout();

		}

		int GetPrice()
		{
			auto record = GetLocalPlayerRecord();
			DungeonNgpList ngps;
			int ngp = 0;
			ngp = int(max(max(ngps["base"],ngps["pop"]),ngps["mt"]));
			if (IsFlagSet("class_change_debug"))
				return 0;

			int respecCost = 250 * GetRespecSkillPoints();
				
			return int(record.level * (1000 + (ngp * 50))) + respecCost;
		}

		void SetFlag(string id, FlagState flag)
		{
			g_flags.Set(id, flag);
		}

		bool IsFlagSet(string id)
		{
			return g_flags.Get(id) != FlagState::Off;
		}

		bool IsBuildingLevel(string id, string level)
		{
			auto gm = cast<Campaign>(g_gameMode);
			int buildingLevel = parseInt(level);
			TownBuilding@ building = gm.m_town.GetBuilding(id);
			if (building is null)
				return false;

			return (building.m_level >= buildingLevel);
		}
		
		int GetRespecSkillPoints()
		{
			auto record = GetLocalPlayerRecord();
			int attunePointsWorth = 0;

			// Attuned items
			for (uint i = 0; i < record.itemForgeAttuned.length(); i++)
			{
				auto item = g_items.GetItem(record.itemForgeAttuned[i]);
				if (item is null)
				{
					PrintError("Couldn't find attuned item with ID " + record.itemForgeAttuned[i]);
					continue;
				}

				attunePointsWorth += GetItemAttuneCost(item);
			}

			// Attuned enemies
			for (uint i = 0; i < record.bestiaryAttunements.length(); i++)
			{
				auto entry = record.bestiaryAttunements[i];
				for (int j = 1; j <= entry.m_attuned; j++)
					attunePointsWorth += entry.GetAttuneCost(j);
			}

			return record.GetSpentSkillpoints() - attunePointsWorth;
		}

		void ClassChange(string newClass)
		{
			auto record = GetLocalPlayerRecord();
			auto player = cast<Player>(record.actor);
			if (player is null)
				return;
			
			int preRenderableIndex = m_preRenderables.findByRef(player);
			if (preRenderableIndex != -1)
				m_preRenderables.removeAt(preRenderableIndex);

			player.RefreshSkills();
			player.RefreshModifiers();
			player.m_record.ClearSkillUpgrades();
			(Network::Message("PlayerRespecSkills")).SendToAll();

			player.DisableModifiers();

			record.charClass = newClass;
			player.Initialize(record);
			(Network::Message("PlayerChangeClass") << newClass).SendToAll();
			//Stop();
		}
		
		
		string GetGuiFilename() override
		{
			return "gui/changeMenu/class_changer.gui";
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto parse = name.split(" ");
			auto record = GetLocalPlayerRecord();
			auto player = cast<Player>(record.actor);

			if (player is null)
				return;

			//for (uint i = 0; i < parse.length(); i++){ print(parse[i] + " "); }
			//print(name);
			if (parse[0] == "unlock")
			{
				SetFlag(parse[1] + "_unlocked", FlagState::Town);
				int unlockCost = GetOrePrice(parse[1]);
				Currency::Spend(0, unlockCost);
				ReloadList();
				m_shopMenu.DoLayout();
			}
			else if (parse[0] == "train")
			{
				if (parse.length() == 3 && parse[2] == "yes")
				{
					if (!Currency::CanAfford(GetPrice()))
						{
							PrintError("Can't afford Class Change");
							return;
						}
						Currency::Spend(GetPrice());
						//print("Now Changing to " + parse[1] + " class...");
						ReloadList();
						ClassChange(parse[1]);
						ShopMenuContent::OnFunc(sender, "close");
				}
				else if (parse.length() == 2)
				{
					g_gameMode.ShowDialog(
						"train " + parse[1],
						Resources::GetString(".mod.classchanger.menu.prompt", {
							{ "gold", formatThousands(GetPrice()) }
						}),
						Resources::GetString(".menu.yes"),
						Resources::GetString(".menu.no"),
						m_shopMenu
					);
				}
			}
			else
			ShopMenuContent::OnFunc(sender, name);
		}
	}
}
