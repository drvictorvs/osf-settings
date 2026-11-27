#pragma once

#include <filesystem>
#include <string>
#include <string_view>
#include <nlohmann/json.hpp>

namespace OSFSettings::Persistence
{
    // internal.json keeps OSF Settings' own state beside the mod value files. Each owner
    // reads and replaces only its own top-level field, so owners never overwrite one another.
    std::filesystem::path InternalDataPath(const std::filesystem::path& directory);

    // A null value removes the field. A missing or malformed file starts empty.
    bool WriteInternalField(const std::filesystem::path& path, std::string_view field, const nlohmann::json& value, std::string& error);
}
