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
		
		void ReloadList() override
		{
			m_wList.PauseScrolling();
			m_wList.ClearChildren();

			auto gm = cast<Campaign>(g_gameMode);
			auto town = gm.m_townLocal;

			auto record = GetLocalPlayerRecord();

			for (uint i = 0; i < g_classes.length(); i++)
			{
				auto customClass = g_classes[i];
				bool classUnlocked = false;
				bool requiredFlags = true;

				//Template Widget
				auto wNewClass = m_wTemplate.Clone();
				wNewClass.SetID("");
				wNewClass.m_visible = true;
				
				//Portrait Widget
				auto wPortrait = cast<PortraitWidget>(wNewClass.GetWidgetById("portrait"));
				auto portraitData = GetLocalPlayerRecord();
				if (wPortrait !is null)
					wPortrait.BindRecord(portraitData);
					wPortrait.SetClass(customClass.m_id);

				//Name Widget
				auto wNameContainer = cast<RectWidget>(wNewClass.GetWidgetById("name-container"));
				if (wNameContainer !is null)
				{
					auto wName = cast<TextWidget>(wNameContainer.GetWidgetById("name"));
					if (wName !is null)
					{	
						//print(customClass.m_name);
						if (customClass.m_name != "")
							wName.SetText(customClass.m_name);
						else
							wName.SetText("Undefined Class");
						
					}
				}
				
				//Check Flags
				if (customClass.m_flags.length() > 0)
				{
					requiredFlags = false;
					for (uint j = 0; j < customClass.m_flags.length(); j++){
						auto currentFlag = customClass.m_flags[j];
						auto parseFlag = currentFlag.split(",");
						print(currentFlag);
						if (parseFlag[0] == "apothecary" || currentFlag == "blacksmith" || currentFlag == "chapel" || currentFlag == "fountain" 
							|| currentFlag == "generalstore" || currentFlag == "guildhall" || currentFlag == "magicshop" || currentFlag == "oretrader" 
							|| currentFlag == "tavern" || currentFlag == "townhall" || currentFlag == "treasury" )
						{
							requiredFlags = IsBuildingLevel(parseFlag[0], parseFlag[1]);
						}
						else if (parseFlag[0] == "dlc")
						{
							requiredFlags = Platform::HasDLC(parseFlag[1]);
						}
						else 
						{
							requiredFlags = IsFlagSet(currentFlag);
						}
					}
				}
				
				//Unlock Class
				if (customClass.m_orePrice == 0 || IsFlagSet(customClass.m_name + "_unlocked"))
					classUnlocked = true;
				
				auto wButtonUnlock = cast<ScalableSpriteButtonWidget>(wNewClass.GetWidgetById("button-unlock"));
				if (wButtonUnlock !is null)
				{
					int unlockCost = GetOrePrice(customClass.m_id);
					wButtonUnlock.m_tooltipTitle = Resources::GetString(".mod.classchanger.menu.unlock");
					wButtonUnlock.m_tooltipText = Resources::GetString(".mod.classchanger.menu.unlock.desc");
					wButtonUnlock.AddTooltipSub(m_spriteOre, formatThousands(unlockCost));
					
					wButtonUnlock.m_enabled = Currency::CanAfford( 0, unlockCost);
					if (requiredFlags == false || customClass.m_orePrice > 0)
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

					if (!Currency::CanAfford(trainCost) || classUnlocked == true)
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
				
			return int(record.level * (1000 +(ngp * 250)));
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
			auto gm = cast<MainMenu>(g_gameMode);
			int buildingLevel = parseInt(level);
			print(level + " " + id);
			auto building = gm.m_town.GetBuilding(id);
			if (building is null)
				return false;

			return (building.m_level >= buildingLevel);
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

			for (uint i = 0; i < parse.length(); i++){
				print(parse[i] + " ");
			}

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
						//print();
						//ClassChange(parse[1]);
				}
				else if (parse.length() == 2)
				{
					g_gameMode.ShowDialog(
						"train-class",
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
