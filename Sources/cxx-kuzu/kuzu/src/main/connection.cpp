#include "main/connection.h"

#include <utility>

#include "common/random_engine.h"

using namespace kuzu::parser;
using namespace kuzu::binder;
using namespace kuzu::common;
using namespace kuzu::planner;
using namespace kuzu::processor;
using namespace kuzu::transaction;

namespace kuzu {
namespace main {

Connection::Connection(Database* database) {
    KU_ASSERT(database != nullptr);
    this->database = database;
    clientContext = std::make_unique<ClientContext>(database);
}

Connection::~Connection() {}

void Connection::setMaxNumThreadForExec(uint64_t numThreads) {
    clientContext->setMaxNumThreadForExec(numThreads);
}

uint64_t Connection::getMaxNumThreadForExec() {
    return clientContext->getMaxNumThreadForExec();
}

std::unique_ptr<PreparedStatement> Connection::prepare(std::string_view query) {
    return clientContext->prepareWithParams(query);
}

std::unique_ptr<PreparedStatement> Connection::prepareWithParams(std::string_view query,
    std::unordered_map<std::string, std::unique_ptr<common::Value>> inputParams) {
    return clientContext->prepareWithParams(query, std::move(inputParams));
}

std::unique_ptr<QueryResult> Connection::query(std::string_view queryStatement) {
    return clientContext->query(queryStatement);
}

std::unique_ptr<QueryResult> Connection::queryWithID(std::string_view queryStatement,
    uint64_t queryID) {
    return clientContext->query(queryStatement, queryID);
}

std::unique_ptr<QueryResult> Connection::queryResultWithError(std::string_view errMsg) {
    return clientContext->queryResultWithError(errMsg);
}

std::unique_ptr<PreparedStatement> Connection::preparedStatementWithError(std::string_view errMsg) {
    return clientContext->preparedStatementWithError(errMsg);
}

void Connection::interrupt() {
    clientContext->interrupt();
}

void Connection::setQueryTimeOut(uint64_t timeoutInMS) {
    clientContext->setQueryTimeOut(timeoutInMS);
}

std::unique_ptr<QueryResult> Connection::executeWithParams(PreparedStatement* preparedStatement,
    std::unordered_map<std::string, std::unique_ptr<Value>> inputParams) {
    return clientContext->executeWithParams(preparedStatement, std::move(inputParams));
}

std::unique_ptr<QueryResult> Connection::executeWithParamsWithID(
    PreparedStatement* preparedStatement,
    std::unordered_map<std::string, std::unique_ptr<Value>> inputParams, uint64_t queryID) {
    return clientContext->executeWithParams(preparedStatement, std::move(inputParams), queryID);
}

void Connection::bindParametersNoLock(PreparedStatement* preparedStatement,
    const std::unordered_map<std::string, std::unique_ptr<Value>>& inputParams) {
    return clientContext->bindParametersNoLock(preparedStatement, inputParams);
}

std::unique_ptr<QueryResult> Connection::executeAndAutoCommitIfNecessaryNoLock(
    PreparedStatement* preparedStatement, uint32_t planIdx) {
    return clientContext->executeNoLock(preparedStatement, planIdx);
}

void Connection::addScalarFunction(std::string name, function::function_set definitions) {
    clientContext->addScalarFunction(name, std::move(definitions));
}

void Connection::removeScalarFunction(std::string name) {
    clientContext->removeScalarFunction(name);
}

} // namespace main
} // namespace kuzu
