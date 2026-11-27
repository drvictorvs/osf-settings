#pragma once

#include <cstddef>
#include <filesystem>
#include <mutex>
#include <string>
#include <string_view>
#include <vector>

namespace OSFSettings
{
    // Mods the player pinned to the top of the menu's mod lists, saved in internal.json.
    // Pins of mods that are not installed stay saved, so a reinstalled mod keeps its pin.
    class PinnedMods
    {
    public:
        static constexpr std::size_t kLimit = 256;
        static PinnedMods& Get();
        void Load(const std::filesystem::path& directory);
        // In the order they were pinned.
        std::vector<std::string> List() const;
        // A valid change applies at once; false means it was rejected or not saved (error says
        // which), and an unsaved change is retried with the next one.
        bool Set(std::string_view mod, bool pinned, std::string& error);
    private:
        mutable std::mutex m_mutex;
        std::filesystem::path m_path;
        std::vector<std::string> m_mods;
        bool m_dirty{};
        bool Save(std::string& error); // Called with m_mutex held.
    };
}
