#include "PinnedMods.h"
#include "Persistence/InternalData.h"
#include "Settings/SettingsSchema.h"

#include <algorithm>
#include <fstream>

namespace OSFSettings
{
    namespace
    {
        constexpr auto kField = "pinnedMods";

        bool ValidMod(std::string_view mod) { return IsValidModId(mod) && mod.size() <= 128; }
    }

    PinnedMods& PinnedMods::Get() { static auto* pins = new PinnedMods; return *pins; }

    void PinnedMods::Load(const std::filesystem::path& directory)
    {
        std::lock_guard lock(m_mutex);
        m_path = Persistence::InternalDataPath(directory);
        m_mods.clear();
        m_dirty = false;
        // Launcher history reports a missing or unreadable file; pins just start empty.
        std::ifstream input(m_path);
        if (!input) return;
        const auto document = nlohmann::json::parse(input, nullptr, false);
        if (document.is_discarded() || !document.is_object()) return;
        const auto pins = document.find(kField);
        if (pins == document.end()) return;
        const auto warn = [&](std::string_view problem) { REX::WARN("Pinned mods {}: {}", m_path.string(), problem); };
        if (!pins->is_array() || pins->size() > kLimit) return warn("invalid format");
        bool skipped = false;
        for (const auto& item : *pins) {
            if (!item.is_string() || !ValidMod(item.get_ref<const std::string&>())) { skipped = true; continue; }
            if (std::ranges::find(m_mods, item.get_ref<const std::string&>()) == m_mods.end()) m_mods.push_back(item.get<std::string>());
        }
        if (skipped) warn("skipped invalid mod ids");
    }

    std::vector<std::string> PinnedMods::List() const
    {
        std::lock_guard lock(m_mutex);
        return m_mods;
    }

    bool PinnedMods::Set(std::string_view mod, bool pinned, std::string& error)
    {
        error.clear();
        if (!ValidMod(mod)) { error = "invalid mod id"; return false; }
        std::lock_guard lock(m_mutex);
        const auto found = std::ranges::find(m_mods, mod);
        if (pinned != (found != m_mods.end())) {
            if (pinned && m_mods.size() >= kLimit) { error = "too many pinned mods"; return false; }
            if (pinned) m_mods.emplace_back(mod);
            else m_mods.erase(found);
            m_dirty = true;
        }
        return Save(error);
    }

    bool PinnedMods::Save(std::string& error)
    {
        // Pins only live in memory until Load names their file, as in tests.
        if (m_path.empty() || !m_dirty) return true;
        // No pins, no field: internal.json keeps only the state that exists.
        const auto value = m_mods.empty() ? nlohmann::json() : nlohmann::json(m_mods);
        if (!Persistence::WriteInternalField(m_path, kField, value, error)) {
            REX::WARN("Pinned mods {}: {}", m_path.string(), error);
            return false;
        }
        m_dirty = false;
        return true;
    }
}
