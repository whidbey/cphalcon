
/**
 * This file is part of the Phalcon Framework.
 *
 * (c) Phalcon Team <team@phalconphp.com>
 *
 * For the full copyright and license information, please view the LICENSE.txt
 * file that was distributed with this source code.
 */

namespace Phalcon\Mvc\Model;

use Phalcon\Di;
use Phalcon\Db\Column;
use Phalcon\DiInterface;
use Phalcon\Mvc\Model\Exception;
use Phalcon\Di\InjectionAwareInterface;
use Phalcon\Mvc\Model\CriteriaInterface;
use Phalcon\Mvc\Model\ResultsetInterface;
use Phalcon\Mvc\Model\Query\BuilderInterface;

/**
 * Phalcon\Mvc\Model\Criteria
 *
 * This class is used to build the array parameter required by
 * Phalcon\Mvc\Model::find() and Phalcon\Mvc\Model::findFirst()
 * using an object-oriented interface.
 *
 * <code>
 * $robots = Robots::query()
 *     ->where("type = :type:")
 *     ->andWhere("year < 2000")
 *     ->bind(["type" => "mechanical"])
 *     ->limit(5, 10)
 *     ->orderBy("name")
 *     ->execute();
 * </code>
 */
class Criteria implements CriteriaInterface, InjectionAwareInterface
{
    protected bindParams;

    protected bindTypes;

    protected hiddenParamNumber = 0;

    protected model;

    protected params;

    /**
     * Sets the DependencyInjector container
     */
    public function setDI(<DiInterface> container) -> void
    {
        let this->params["di"] = container;
    }

    /**
     * Returns the DependencyInjector container
     */
    public function getDI() -> <DiInterface>
    {
        return this->params["di"];
    }

    /**
     * Set a model on which the query will be executed
     */
    public function setModelName(string! modelName) -> <CriteriaInterface>
    {
        let this->model = modelName;
        return this;
    }

    /**
     * Returns an internal model name on which the criteria will be applied
     */
    public function getModelName() -> string
    {
        return this->model;
    }

    /**
     * Sets the bound parameters in the criteria
     * This method replaces all previously set bound parameters
     */
    public function bind(array! bindParams, bool merge = false) -> <CriteriaInterface>
    {
        var bind;

        if merge {
            if isset this->params["bind"] {
                let bind = this->params["bind"];
            } else {
                let bind = null;
            }
            if typeof bind == "array" {
                let this->params["bind"] = bind + bindParams;
            } else {
                let this->params["bind"] = bindParams;
            }
        } else {
            let this->params["bind"] = bindParams;
        }

        return this;
    }

    /**
     * Sets the bind types in the criteria
     * This method replaces all previously set bound parameters
     */
    public function bindTypes(array! bindTypes) -> <CriteriaInterface>
    {
        let this->params["bindTypes"] = bindTypes;
        return this;
    }

    /**
     * Sets SELECT DISTINCT / SELECT ALL flag
     */
     public function distinct(var distinct) -> <CriteriaInterface>
     {
         let this->params["distinct"] = distinct;
         return this;
     }

    /**
     * Sets the columns to be queried
     *
     *<code>
     * $criteria->columns(
     *     [
     *         "id",
     *         "name",
     *     ]
     * );
     *</code>
     *
     * @param string|array columns
     */
    public function columns(var columns) -> <CriteriaInterface>
    {
        let this->params["columns"] = columns;
        return this;
    }

    /**
     * Adds an INNER join to the query
     *
     *<code>
     * $criteria->join("Robots");
     * $criteria->join("Robots", "r.id = RobotsParts.robots_id");
     * $criteria->join("Robots", "r.id = RobotsParts.robots_id", "r");
     * $criteria->join("Robots", "r.id = RobotsParts.robots_id", "r", "LEFT");
     *</code>
     */
    public function join(string! model, var conditions = null, var alias = null, var type = null) -> <CriteriaInterface>
    {
        var join, mergedJoins, currentJoins;

        let join = [model, conditions, alias, type];
        if fetch currentJoins, this->params["joins"] {
            if typeof currentJoins == "array" {
                let mergedJoins = array_merge(currentJoins, [join]);
            } else {
                let mergedJoins = [join];
            }
        } else {
            let mergedJoins = [join];
        }

        let this->params["joins"] = mergedJoins;

        return this;
    }

    /**
     * Adds an INNER join to the query
     *
     *<code>
     * $criteria->innerJoin("Robots");
     * $criteria->innerJoin("Robots", "r.id = RobotsParts.robots_id");
     * $criteria->innerJoin("Robots", "r.id = RobotsParts.robots_id", "r");
     *</code>
     */
    public function innerJoin(string! model, var conditions = null, var alias = null) -> <CriteriaInterface>
    {
        return this->join(model, conditions, alias, "INNER");
    }

    /**
     * Adds a LEFT join to the query
     *
     *<code>
     * $criteria->leftJoin("Robots", "r.id = RobotsParts.robots_id", "r");
     *</code>
     */
    public function leftJoin(string! model, var conditions = null, var alias = null) -> <CriteriaInterface>
    {
        return this->join(model, conditions, alias, "LEFT");
    }

    /**
     * Adds a RIGHT join to the query
     *
     *<code>
     * $criteria->rightJoin("Robots", "r.id = RobotsParts.robots_id", "r");
     *</code>
     */
    public function rightJoin(string! model, conditions = null, alias = null) -> <CriteriaInterface>
    {
        return this->join(model, conditions, alias, "RIGHT");
    }

    /**
     * Sets the conditions parameter in the criteria
     */
    public function where(string! conditions, var bindParams = null, var bindTypes = null) -> <CriteriaInterface>
    {
        var currentBindParams, currentBindTypes;

        let this->params["conditions"] = conditions;

        /**
         * Update or merge existing bound parameters
         */
        if typeof bindParams == "array" {
            if fetch currentBindParams, this->params["bind"] {
                let this->params["bind"] = array_merge(currentBindParams, bindParams);
            } else {
                let this->params["bind"] = bindParams;
            }
        }

        /**
         * Update or merge existing bind types parameters
         */
        if typeof bindTypes == "array" {
            if fetch currentBindTypes, this->params["bindTypes"] {
                let this->params["bindTypes"] = array_merge(currentBindTypes, bindTypes);
            } else {
                let this->params["bindTypes"] = bindTypes;
            }
        }

        return this;
    }

    /**
     * Appends a condition to the current conditions using an AND operator
     */
    public function andWhere(string! conditions, var bindParams = null, var bindTypes = null) -> <CriteriaInterface>
    {
        var currentConditions;

        if fetch currentConditions, this->params["conditions"] {
            let conditions = "(" . currentConditions . ") AND (" . conditions . ")";
        }

        return this->where(conditions, bindParams, bindTypes);
    }

    /**
     * Appends a condition to the current conditions using an OR operator
     */
    public function orWhere(string! conditions, var bindParams = null, var bindTypes = null) -> <CriteriaInterface>
    {
        var currentConditions;

        if fetch currentConditions, this->params["conditions"] {
            let conditions = "(" . currentConditions . ") OR (" . conditions . ")";
        }

        return this->where(conditions, bindParams, bindTypes);
    }

    /**
     * Appends a BETWEEN condition to the current conditions
     *
     *<code>
     * $criteria->betweenWhere("price", 100.25, 200.50);
     *</code>
     */
    public function betweenWhere(string! expr, var minimum, var maximum) -> <CriteriaInterface>
    {
        var hiddenParam, minimumKey, nextHiddenParam, maximumKey;

        let hiddenParam = this->hiddenParamNumber, nextHiddenParam = hiddenParam + 1;

        /**
         * Minimum key with auto bind-params
         */
        let minimumKey = "ACP" . hiddenParam;

        /**
         * Maximum key with auto bind-params
         */
        let maximumKey = "ACP" . nextHiddenParam;

        /**
         * Create a standard BETWEEN condition with bind params
         * Append the BETWEEN to the current conditions using and "and"
         */
        this->andWhere(
            expr . " BETWEEN :" . minimumKey . ": AND :" . maximumKey . ":",
            [minimumKey: minimum, maximumKey: maximum]
        );

        let nextHiddenParam++, this->hiddenParamNumber = nextHiddenParam;

        return this;
    }

    /**
     * Appends a NOT BETWEEN condition to the current conditions
     *
     *<code>
     * $criteria->notBetweenWhere("price", 100.25, 200.50);
     *</code>
     */
    public function notBetweenWhere(string! expr, var minimum, var maximum) -> <CriteriaInterface>
    {
        var hiddenParam, nextHiddenParam, minimumKey, maximumKey;

        let hiddenParam = this->hiddenParamNumber;

        let nextHiddenParam = hiddenParam + 1;

        /**
         * Minimum key with auto bind-params
         */
        let minimumKey = "ACP" . hiddenParam;

        /**
         * Maximum key with auto bind-params
         */
        let maximumKey = "ACP" . nextHiddenParam;

        /**
         * Create a standard BETWEEN condition with bind params
         * Append the BETWEEN to the current conditions using and "and"
         */
        this->andWhere(
            expr . " NOT BETWEEN :" . minimumKey . ": AND :"  . maximumKey . ":",
            [minimumKey: minimum, maximumKey: maximum]
        );

        let nextHiddenParam++;

        let this->hiddenParamNumber = nextHiddenParam;

        return this;
    }

    /**
     * Appends an IN condition to the current conditions
     *
     * <code>
     * $criteria->inWhere("id", [1, 2, 3]);
     * </code>
     */
    public function inWhere(string! expr, array! values) -> <CriteriaInterface>
    {
        var hiddenParam, bindParams, bindKeys, value, key, queryKey;

        if !count(values) {
            this->andWhere(expr . " != " . expr);
            return this;
        }

        let hiddenParam = this->hiddenParamNumber;

        let bindParams = [], bindKeys = [];
        for value in values {

            /**
             * Key with auto bind-params
             */
            let key = "ACP" . hiddenParam;

            let queryKey = ":" . key . ":";

            let bindKeys[] = queryKey, bindParams[key] = value;

            let hiddenParam++;
        }

        /**
         * Create a standard IN condition with bind params
         * Append the IN to the current conditions using and "and"
         */
        this->andWhere(expr . " IN (" . join(", ", bindKeys) . ")", bindParams);

        let this->hiddenParamNumber = hiddenParam;

        return this;
    }

    /**
     * Appends a NOT IN condition to the current conditions
     *
     *<code>
     * $criteria->notInWhere("id", [1, 2, 3]);
     *</code>
     */
    public function notInWhere(string! expr, array! values) -> <CriteriaInterface>
    {
        var hiddenParam, bindParams, bindKeys, value, key;

        let hiddenParam = this->hiddenParamNumber;

        let bindParams = [], bindKeys = [];
        for value in values {

            /**
             * Key with auto bind-params
             */
            let key = "ACP" . hiddenParam,
                bindKeys[] = ":" . key . ":",
                bindParams[key] = value;

            let hiddenParam++;
        }

        /**
         * Create a standard IN condition with bind params
         * Append the IN to the current conditions using and "and"
         */
        this->andWhere(expr . " NOT IN (" . join(", ", bindKeys) . ")", bindParams);
        let this->hiddenParamNumber = hiddenParam;

        return this;
    }

    /**
     * Adds the conditions parameter to the criteria
     */
    public function conditions(string! conditions) -> <CriteriaInterface>
    {
        let this->params["conditions"] = conditions;
        return this;
    }

    /**
     * Adds the order-by clause to the criteria
     */
    public function orderBy(string! orderColumns) -> <CriteriaInterface>
    {
        let this->params["order"] = orderColumns;
        return this;
    }

    /**
     * Adds the group-by clause to the criteria
     */
    public function groupBy(var group) -> <CriteriaInterface>
    {
        let this->params["group"] = group;
        return this;
    }

    /**
     * Adds the having clause to the criteria
     */
    public function having(var having) -> <CriteriaInterface>
    {
        let this->params["having"] = having;
        return this;
    }

    /**
     * Adds the limit parameter to the criteria.
     *
     * <code>
     * $criteria->limit(100);
     * $criteria->limit(100, 200);
     * $criteria->limit("100", "200");
     * </code>
     */
    public function limit(int limit, var offset = null) -> <CriteriaInterface>
    {
        let limit = abs(limit);

        if unlikely limit == 0 {
            return this;
        }

        if is_numeric(offset) {
            let offset = abs((int) offset);
            let this->params["limit"] = ["number": limit, "offset": offset];
        } else {
            let this->params["limit"] = limit;
        }

        return this;
    }

    /**
     * Adds the "for_update" parameter to the criteria
     */
    public function forUpdate(bool forUpdate = true) -> <CriteriaInterface>
    {
        let this->params["for_update"] = forUpdate;
        return this;
    }

    /**
     * Adds the "shared_lock" parameter to the criteria
     */
    public function sharedLock(bool sharedLock = true) -> <CriteriaInterface>
    {
        let this->params["shared_lock"] = sharedLock;
        return this;
    }

    /**
     * Sets the cache options in the criteria
     * This method replaces all previously set cache options
     */
    public function cache(array! cache) -> <CriteriaInterface>
    {
        let this->params["cache"] = cache;
        return this;
    }

    /**
     * Returns the conditions parameter in the criteria
     */
    public function getWhere() -> string | null
    {
        var conditions;
        if fetch conditions, this->params["conditions"] {
            return conditions;
        }
        return null;
    }

    /**
     * Returns the columns to be queried
     *
     * @return string|array|null
     */
    public function getColumns() -> string | null
    {
        var columns;
        if fetch columns, this->params["columns"] {
            return columns;
        }
        return null;
    }

    /**
     * Returns the conditions parameter in the criteria
     */
    public function getConditions() -> string | null
    {
        var conditions;
        if fetch conditions, this->params["conditions"] {
            return conditions;
        }
        return null;
    }

    /**
     * Returns the limit parameter in the criteria, which will be
     * an integer if limit was set without an offset,
     * an array with 'number' and 'offset' keys if an offset was set with the limit,
     * or null if limit has not been set.
     *
     * @return int|array|null
     */
    public function getLimit() -> string | null
    {
        var limit;
        if fetch limit, this->params["limit"] {
            return limit;
        }
        return null;
    }

    /**
     * Returns the order clause in the criteria
     */
    public function getOrderBy() -> string | null
    {
        var order;
        if fetch order, this->params["order"] {
            return order;
        }
        return null;
    }

    /**
     * Returns the group clause in the criteria
     */
    public function getGroupBy()
    {
        var group;
        if fetch group, this->params["group"] {
            return group;
        }
        return null;
    }

    /**
     * Returns the having clause in the criteria
     */
    public function getHaving()
    {
        var having;
        if fetch having, this->params["having"] {
            return having;
        }
        return null;
    }

    /**
     * Returns all the parameters defined in the criteria
     */
    public function getParams() -> array
    {
        return this->params;
    }

    /**
     * Builds a Phalcon\Mvc\Model\Criteria based on an input array like $_POST
     */
    public static function fromInput(<DiInterface> container, string! modelName, array! data, string! operator = "AND") -> <CriteriaInterface>
    {
        var attribute, conditions, field, value, type, metaData,
            model, dataTypes, bind, criteria, columnMap;

        let conditions = [];
        if count(data) {

            let metaData = container->getShared("modelsMetadata");

            let model = new {modelName}(null, container),
                dataTypes = metaData->getDataTypes(model),
                columnMap = metaData->getReverseColumnMap(model);

            /**
             * We look for attributes in the array passed as data
             */
            let bind = [];
            for field, value in data {

                if typeof columnMap == "array" && count(columnMap) {
                    let attribute = columnMap[field];
                } else {
                    let attribute = field;
                }

                if fetch type, dataTypes[attribute] {
                    if value !== null && value !== "" {

                        if type == Column::TYPE_VARCHAR {
                            /**
                             * For varchar types we use LIKE operator
                             */
                            let conditions[] = "[" . field . "] LIKE :" . field . ":", bind[field] = "%" . value . "%";
                            continue;
                        }

                        /**
                         * For the rest of data types we use a plain = operator
                         */
                        let conditions[] = "[" . field . "] = :" . field . ":", bind[field] = value;
                    }
                }
            }
        }

        /**
         * Create an object instance and pass the parameters to it
         */
        let criteria = new self();
        if count(conditions) {
            criteria->where(join(" " . operator . " ", conditions));
            criteria->bind(bind);
        }

        criteria->setModelName(modelName);
        return criteria;
    }

    /**
     * Creates a query builder from criteria.
     *
     * <code>
     * $builder = Robots::query()
     *     ->where("type = :type:")
     *     ->bind(["type" => "mechanical"])
     *     ->createBuilder();
     * </code>
     */
    public function createBuilder() -> <BuilderInterface>
    {
        var container, manager, builder;

        let container = this->getDI();
        if typeof container != "object" {
            let container = Di::getDefault();
            this->setDI(container);
        }

        let manager = <ManagerInterface> container->getShared("modelsManager");

        /**
         * Builds a query with the passed parameters
         */
        let builder = manager->createBuilder(this->params);
        builder->from(this->model);

        return builder;
    }

    /**
     * Executes a find using the parameters built with the criteria
     */
    public function execute() -> <ResultsetInterface>
    {
        var model;

        let model = this->getModelName();
        if typeof model != "string" {
            throw new Exception("Model name must be string");
        }

        return {model}::find(this->getParams());
    }
}