#include "extension/loaded_extension.h"
#include "generated_extension_loader.h"

namespace kuzu {
namespace extension {

void loadLinkedExtensions([[maybe_unused]] main::ClientContext* context,
    [[maybe_unused]] std::vector<LoadedExtension>& loadedExtensions) {
    {
        algo_extension::AlgoExtension extension{};
        extension.load(context);
        loadedExtensions.push_back(LoadedExtension(algo_extension::AlgoExtension::EXTENSION_NAME, " ",
            ExtensionSource::STATIC_LINKED));
    }
{
        fts_extension::FtsExtension extension{};
        extension.load(context);
        loadedExtensions.push_back(LoadedExtension(fts_extension::FtsExtension::EXTENSION_NAME, " ",
            ExtensionSource::STATIC_LINKED));
    }
{
        json_extension::JsonExtension extension{};
        extension.load(context);
        loadedExtensions.push_back(LoadedExtension(json_extension::JsonExtension::EXTENSION_NAME, " ",
            ExtensionSource::STATIC_LINKED));
    }
{
        vector_extension::VectorExtension extension{};
        extension.load(context);
        loadedExtensions.push_back(LoadedExtension(vector_extension::VectorExtension::EXTENSION_NAME, " ",
            ExtensionSource::STATIC_LINKED));
    }

}

} // namespace extension
} // namespace kuzu
