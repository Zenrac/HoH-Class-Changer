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

			for (uint i = 0; i < g_classes.length(); i++)
			{
				auto customClass = g_classes[i];
				bool classUnlocked = false;
				bool requiredFlags = true;
				Widget@ wNewClass = null;

				if (customClass.m_name != "")
					wNewClass.m_tooltipText = customClass.m_name;
				else
					wNewClass.m_tooltipText = "Undefined Class";
				//Check Flags
				if (customClass.m_flags !is null)
				{
					requiredFlags = false;
					for (uint j = 0; j < customClass.m_flags.length(); j++){
						auto currentFlag = customClass.m_flags[j];
						if (currentFlag == "apothecary" || currentFlag == "blacksmith" || currentFlag == "chapel" || currentFlag == "fountain" 
							|| currentFlag == "generalstore" || currentFlag == "guildhall" || currentFlag == "magicshop" || currentFlag == "oretrader" 
							|| currentFlag == "tavern" || currentFlag == "townhall" || currentFlag == "treasury" )
						{
							int buildingLevel = 0;
							buildingLevel = parseInt(customClass.m_flags[j+1]);
							requiredFlags = IsBuildingLevel(currentFlag, buildingLevel);
							j++;
						}
						else {
							requiredFlags = IsFlagSet(currentFlag);
						}
						requiredFlags = Platform::HasDLC(Resources::GetString(currentFlag));
					}
				}
				
				//Unlock Class
				
				auto wButtonUnlock = cast<ScalableSpriteButtonWidget>(wNewClass.GetWidgetById("button-unlock"));
				if (wButtonUnlock !is null && customClass.m_price > 0)
				{
					int oreCost = 0;
					oreCost = customClass.m_price;
					wButtonUnlock.SetText(Resources::GetString("Unlock"));
					wButtonUnlock.m_tooltipText = Resources::GetString("ore");
					wButtonUnlock.AddTooltipSub(m_spriteOre, oreCost);
					wButtonUnlock.m_enabled = true;
					
					if (!Currency::CanAfford( 0, oreCost) || requiredFlags == false || IsFlagSet(customClass.m_name + "_unlocked"))
					{
						wButtonUnlock.m_enabled = false;
					}
					else
					{
						wButtonUnlock.m_enabled = false;
						classUnlocked = true;
					}
				}

				//Buy Class
				auto wButtonBuy = cast<ScalableSpriteButtonWidget>(wNewClass.GetWidgetById("button-buy"));
				if (wButtonBuy !is null)
				{
					int buyCost = GetPrice(); 

					wButtonBuy.SetText(Resources::GetString("Buy"));
					wButtonBuy.m_tooltipText = Resources::GetString("cost");
					wButtonBuy.AddTooltipSub(m_spriteGold, formatThousands(buyCost));

					if (!Currency::CanAfford(buyCost) || classUnlocked == true)
						wButtonBuy.m_enabled = false;
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
			return int(record.level * (1000 +(ngp * 250)));
		}

		bool IsFlagSet(string id)
		{
			return g_flags.Get(id) != FlagState::Off;
		}

		bool IsBuildingLevel(string id, int level)
		{
			auto gm = cast<MainMenu>(g_gameMode);

			auto building = gm.m_town.GetBuilding(id);
			if (building is null)
				return false;

			return (building.m_level >= level);
		}

		void ClassChange(string newClass)
		{
			auto record = GetLocalPlayerRecord();
			auto player = cast<Player>(record.actor);
			record.charClass = newClass;
			player.Initialize(record);
		}
		
		
		string GetGuiFilename() override
		{
			return "gui/class_changer.gui";
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto player = GetLocalPlayer();
			if (name == "unlock-class")
			{
				g_flags.Set(name + "_unlocked", FlagState::Town);
				Currency::Spend(0, parseInt(sender.m_tooltipSubtexts[0].m_text));
			}
			else if (name == "buy-class")
			{
				g_gameMode.ShowDialog(
					"buy-class",
					Resources::GetString(".mod.classchanger.menu.prompt", {
						{ "gold", formatThousands(GetPrice()) }
					}),
					Resources::GetString(".menu.yes"),
					Resources::GetString(".menu.no"),
					m_shopMenu
				);
			}
			else if (name == "buy-class yes")
			{
				if (!Currency::CanAfford(GetPrice()))
				{
					PrintError("Can't afford Class Change");
					return;
				}
				Currency::Spend(GetPrice());
				player.m_record.ClearSkillUpgrades();

				player.RefreshSkills();
				player.RefreshModifiers();
				(Network::Message("PlayerRespecSkills")).SendToAll();

				ClassChange(name);
			} 
			else
			ShopMenuContent::OnFunc(sender, name);
			
			ReloadList();
			m_shopMenu.DoLayout();
		}
	}
}
