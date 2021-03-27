namespace ClassChanger
{
	class ClassEntry
	{
		string m_id;
		string m_name;
		int m_price;
		array<string> m_flags;

		
		ClassEntry(UnitPtr unit, SValue& params)
		{
			m_id = GetParamString(unit, params, "class-id");
			m_name = GetParamString(unit, params, GetModClassName(m_id));
			m_price = GetParamInt(unit, params, "ore-price");
			auto arrFlags = GetParamArray(unit, params, "flags");
			for (uint i = 0; i < arrFlags.length(); i++){
				m_flags.insertLast(arrFlags[i].GetString());
				print (m_flags[i]);
			}
			
		}	
		
		string GetModClassName(string id)
		{
			auto enabledMods = HwrSaves::GetEnabledMods();
			for (uint i = 0; i < enabledMods.length(); i++)
			{
				auto mod = enabledMods[i];
				auto sval = mod.Data;

				auto arrCustomClasses = GetParamArray(UnitPtr(), sval, "custom-character-classes", false);
				if (arrCustomClasses !is null)
				{
					for (uint j = 0; j < arrCustomClasses.length(); j++)
					{
						auto charClass = arrCustomClasses[j];
						if (charClass.GetType() == SValueType::Dictionary)
						{
							string classId = GetParamString(UnitPtr(), charClass, "id");
							if (classId == id)
								return GetParamString(UnitPtr(), charClass, "name");
						}
						else if (charClass.GetType() == SValueType::String && charClass.GetString() == id)
							return id;
					}
				}
			}
			return id;
		}
	}
	
	ClassChangerMenuContent@ g_menu;
	array<ClassEntry@> g_classes;
	
	
	void AddClass(SValue@ sval){
		auto arrClasses = sval.GetArray();
		for (uint i = 0; i < arrClasses.length(); i++)
		{
			auto svClass = arrClasses[i];
			string className = GetParamString(UnitPtr(), svClass, "class-id");
			
			auto newClass = cast<ClassEntry>(InstantiateClass(className, UnitPtr(), svClass));
			if (newClass is null){
				PrintError("The " + className + "class is causing a problem");
				continue;
			}
			g_classes.insertLast(newClass);
		}
	}	
}