#include "InternalData.h"
#include "AtomicFile.h"

#include <fstream>
#include <mutex>

namespace OSFSettings::Persistence
{
    std::filesystem::path InternalDataPath(const std::filesystem::path& directory)
    {
        return directory / "internal.json";
    }

    bool WriteInternalField(const std::filesystem::path& path, std::string_view field, const nlohmann::json& value, std::string& error)
    {
        // One lock for every owner: each write rereads the file, so none can drop another's field.
        static std::mutex mutex;
        std::lock_guard lock(mutex);
        auto document = nlohmann::json::object();
        if (std::ifstream input{ path }) {
            auto current = nlohmann::json::parse(input, nullptr, false);
            if (!current.is_discarded() && current.is_object()) document = std::move(current);
        }
        const std::string name(field);
        if (value.is_null()) document.erase(name);
        else document[name] = value;
        return WriteAtomic(path, document.dump(2) + '\n', error);
    }
}
