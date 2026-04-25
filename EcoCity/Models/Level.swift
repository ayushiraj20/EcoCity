import Foundation

struct Level: Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let iconName: String // SF Symbol name
    let educationalTextBefore: String
    let educationalTextAfter: String
    
    static let allLevels: [Level] = [
        Level(id: 1, title: "Plant Trees", description: "Tap the green area to plant 5 trees and reduce CO2 levels in the city.", iconName: "tree.fill",
              educationalTextBefore: "A lack of trees causes high CO2 levels and poor AQI. People suffer from respiratory issues, lowering life expectancy by years. Planting trees is essential to trap carbon and release oxygen.",
              educationalTextAfter: "🌳 Each mature tree absorbs ~48 lbs of CO2 per year and produces enough oxygen for 2 people.\n\n📊 Impact: AQI reduced by 50 points. Urban trees also cool cities by up to 10°F through shade and evapotranspiration, reducing heat-related deaths.\n\n💚 Health Benefit: Communities near green spaces have 16% lower mortality rates and significantly reduced stress levels."),
        Level(id: 2, title: "Clean River", description: "Tap on garbage in the river to remove all 7 waste items and restore clean water.", iconName: "water.waves",
              educationalTextBefore: "Garbage and plastic waste in rivers destroy aquatic ecosystems and pollute drinking water sources. This leads to waterborne diseases and severe health risks for the population.",
              educationalTextAfter: "🏞️ Clean rivers support over 100,000 species and provide safe drinking water for billions.\n\n📊 Impact: Removing 7 waste sources eliminated microplastic contamination. A single piece of plastic can take 450 years to decompose in water.\n\n💚 Health Benefit: Clean water reduces waterborne diseases like cholera and dysentery by up to 80%, directly increasing life expectancy."),
        Level(id: 3, title: "Solar Power", description: "Tap rooftops to install 3 solar panel systems and generate clean energy.", iconName: "sun.max.fill",
              educationalTextBefore: "Relying on fossil fuels for electricity generation releases massive amounts of greenhouse gases, heavily contributing to global warming and deadly air pollution.",
              educationalTextAfter: "☀️ Each solar panel system offsets ~3-4 tons of carbon emissions annually — equivalent to planting 100 trees.\n\n📊 Impact: 3 rooftops now generate clean energy, eliminating 12 tons of CO2 per year. Solar energy is now the cheapest source of electricity in history.\n\n💚 Health Benefit: Replacing coal with solar prevents respiratory diseases caused by particulate matter, saving an estimated 51,999 lives per year in the US alone."),
        Level(id: 4, title: "Wind Energy", description: "Tap the wind pads to build 3 turbines and harness renewable wind power.", iconName: "wind",
              educationalTextBefore: "Traditional power grids constantly burn finite resources, pumping particulate matter into the sky that causes asthma and drastically reduces the region's air quality.",
              educationalTextAfter: "💨 A single large wind turbine can power over 1,500 homes per year with zero emissions.\n\n📊 Impact: 3 turbines installed, generating enough clean electricity for 4,500 homes. Wind energy uses 99% less water than coal power plants.\n\n💚 Health Benefit: Eliminating fossil fuel particulates prevents 7 million premature deaths globally each year according to the WHO."),
        Level(id: 5, title: "Hydro Power", description: "Tap the dam site to build a hydroelectric dam and generate power from water flow.", iconName: "bolt.fill",
              educationalTextBefore: "High energy demands usually mean burning more coal, spreading thick smog over the city and poisoning the air residents breathe every day.",
              educationalTextAfter: "🌊 Hydroelectric dams produce steady baseload power with a lifespan of 50-100 years.\n\n📊 Impact: The dam now generates 24/7 clean energy. Hydropower is the world's largest source of renewable electricity, providing 16% of global power.\n\n💚 Health Benefit: Replacing one coal plant with hydro prevents 3.5 million tons of CO2 and eliminates mercury contamination in local water supplies."),
        Level(id: 6, title: "Electric Vehicles", description: "Tap on gas cars to replace all 5 polluting vehicles with clean electric ones.", iconName: "car.circle.fill",
              educationalTextBefore: "Gasoline and diesel vehicles emit toxic exhaust fumes right at street level where people breathe. This smog is a leading cause of lung disease and reduced life expectancy.",
              educationalTextAfter: "🚗 Each EV eliminates 4.6 metric tons of CO2 per year compared to a gasoline car.\n\n📊 Impact: 5 gas cars replaced, removing 23 tons of annual CO2 emissions and eliminating toxic nitrogen dioxide at street level.\n\n💚 Health Benefit: Cities with high EV adoption see 20-30% reduction in childhood asthma cases and a measurable increase in life expectancy within just 5 years."),
        Level(id: 7, title: "Smoke Filters", description: "Tap the factory chimneys to install 2 industrial filters and clean up emissions.", iconName: "smoke.fill",
              educationalTextBefore: "Unregulated factories spew toxic chemicals and particulate matter directly into the atmosphere, creating acid rain and causing severe health crises in neighboring towns.",
              educationalTextAfter: "🏭 Industrial scrubbers capture up to 99% of toxic particulates including sulfur dioxide and heavy metals.\n\n📊 Impact: 2 chimneys filtered, eliminating acid rain risk and removing fine particulate matter (PM2.5) that penetrates deep into lungs.\n\n💚 Health Benefit: Factory emission controls reduce lung cancer rates by 30% in surrounding communities and prevent devastating acid rain damage to crops and buildings."),
        Level(id: 8, title: "Water Treatment", description: "Tap on toxic pipes to install 2 treatment systems and stop industrial pollution.", iconName: "drop.circle.fill",
              educationalTextBefore: "Factories dumping untreated toxic chemicals into the river poison the entire water supply. This causes immediate harm to aquatic life and makes the water extremely dangerous for humans.",
              educationalTextAfter: "🧪 Water treatment plants neutralize heavy metals, chemical solvents, and biological contaminants before discharge.\n\n📊 Impact: 2 toxic discharge points neutralized. Modern treatment removes 99.9% of harmful pathogens and reduces chemical oxygen demand by 95%.\n\n💚 Health Benefit: Clean industrial discharge restores fish populations within 2 years, eliminates bioaccumulation of toxins in the food chain, and makes downstream water safe for drinking.")
    ]
}
