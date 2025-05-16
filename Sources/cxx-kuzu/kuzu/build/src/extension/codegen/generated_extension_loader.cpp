#include "generated_extension_loader.h"

namespace kuzu {
namespace extension {

void loadLinkedExtensions([[maybe_unused]] main::ClientContext* context) {
        {
        fts_extension::FtsExtension extension{};
        extension.load(context);
    }
    {
        json_extension::JsonExtension extension{};
        extension.load(context);
    }
    {
        vector_extension::VectorExtension extension{};
        extension.load(context);
    }
    {
        algo_extension::AlgoExtension extension{};
        extension.load(context);
    }

}

} // namespace extension
} // namespace kuzu
