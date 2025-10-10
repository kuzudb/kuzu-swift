#pragma once

#include "main/client_context.h"
#include "algo_extension.h"
#include "fts_extension.h"
#include "json_extension.h"
#include "vector_extension.h"


namespace kuzu {
namespace extension {

void loadLinkedExtensions(main::ClientContext* context, std::vector<LoadedExtension>& loadedExtensions);

} // namespace extension
} // namespace kuzu
