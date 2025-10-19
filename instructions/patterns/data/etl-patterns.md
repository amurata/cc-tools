# ETL (Extract, Transform, Load) Patterns

Data pipeline patterns for ETL and data processing workflows.

## ETL Architecture

### Basic ETL Pipeline
```python
from typing import Any, Dict, List
import pandas as pd
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class ETLConfig:
    source_config: Dict[str, Any]
    transform_rules: List[Dict[str, Any]]
    destination_config: Dict[str, Any]
    error_handling: str = "fail"  # fail, skip, retry

class ETLPipeline(ABC):
    def __init__(self, config: ETLConfig):
        self.config = config
    
    @abstractmethod
    def extract(self) -> pd.DataFrame:
        pass
    
    @abstractmethod
    def transform(self, data: pd.DataFrame) -> pd.DataFrame:
        pass
    
    @abstractmethod
    def load(self, data: pd.DataFrame) -> None:
        pass
    
    def run(self) -> None:
        try:
            # Extract
            raw_data = self.extract()
            
            # Transform
            transformed_data = self.transform(raw_data)
            
            # Load
            self.load(transformed_data)
            
        except Exception as e:
            self.handle_error(e)
```

## Extract Patterns

### Multi-Source Extraction
```python
class DataExtractor:
    def __init__(self):
        self.extractors = {
            'database': self.extract_from_database,
            'api': self.extract_from_api,
            'file': self.extract_from_file,
            's3': self.extract_from_s3
        }
    
    def extract_from_database(self, config: Dict) -> pd.DataFrame:
        import sqlalchemy
        
        engine = sqlalchemy.create_engine(config['connection_string'])
        query = config['query']
        
        return pd.read_sql(query, engine)
    
    def extract_from_api(self, config: Dict) -> pd.DataFrame:
        import requests
        
        response = requests.get(
            config['url'],
            headers=config.get('headers', {}),
            params=config.get('params', {})
        )
        response.raise_for_status()
        
        return pd.DataFrame(response.json())
    
    def extract_from_file(self, config: Dict) -> pd.DataFrame:
        file_type = config['file_type']
        path = config['path']
        
        if file_type == 'csv':
            return pd.read_csv(path)
        elif file_type == 'json':
            return pd.read_json(path)
        elif file_type == 'parquet':
            return pd.read_parquet(path)
        else:
            raise ValueError(f"Unsupported file type: {file_type}")
```

### Incremental Extraction
```python
class IncrementalExtractor:
    def __init__(self, state_manager):
        self.state_manager = state_manager
    
    def extract_incremental(self, source: str, config: Dict) -> pd.DataFrame:
        # Get last extraction timestamp
        last_timestamp = self.state_manager.get_last_timestamp(source)
        
        # Extract only new data
        query = f"""
        SELECT * FROM {config['table']}
        WHERE updated_at > '{last_timestamp}'
        ORDER BY updated_at
        """
        
        data = pd.read_sql(query, config['connection'])
        
        # Update state
        if not data.empty:
            max_timestamp = data['updated_at'].max()
            self.state_manager.update_timestamp(source, max_timestamp)
        
        return data
```

## Transform Patterns

### Data Transformation Pipeline
```python
class DataTransformer:
    def __init__(self):
        self.transformations = []
    
    def add_transformation(self, func, **kwargs):
        self.transformations.append((func, kwargs))
        return self
    
    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        for func, kwargs in self.transformations:
            df = func(df, **kwargs)
        return df

# Transformation functions
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    # Remove duplicates
    df = df.drop_duplicates()
    
    # Handle missing values
    df = df.fillna({
        'numeric_col': 0,
        'string_col': 'unknown'
    })
    
    return df

def validate_data(df: pd.DataFrame, rules: Dict) -> pd.DataFrame:
    for column, rule in rules.items():
        if 'min' in rule:
            df = df[df[column] >= rule['min']]
        if 'max' in rule:
            df = df[df[column] <= rule['max']]
        if 'values' in rule:
            df = df[df[column].isin(rule['values'])]
    
    return df

def enrich_data(df: pd.DataFrame, lookup_df: pd.DataFrame) -> pd.DataFrame:
    return df.merge(
        lookup_df,
        on='key_column',
        how='left'
    )
```

### Complex Transformations
```python
class AdvancedTransformer:
    @staticmethod
    def aggregate_time_series(df: pd.DataFrame, 
                            time_column: str,
                            frequency: str) -> pd.DataFrame:
        df[time_column] = pd.to_datetime(df[time_column])
        df = df.set_index(time_column)
        
        # Resample and aggregate
        aggregated = df.resample(frequency).agg({
            'value': 'sum',
            'count': 'count',
            'amount': 'mean'
        })
        
        return aggregated.reset_index()
    
    @staticmethod
    def pivot_data(df: pd.DataFrame,
                  index: str,
                  columns: str,
                  values: str) -> pd.DataFrame:
        return df.pivot_table(
            index=index,
            columns=columns,
            values=values,
            aggfunc='sum',
            fill_value=0
        )
    
    @staticmethod
    def normalize_json(df: pd.DataFrame, json_column: str) -> pd.DataFrame:
        import json
        
        # Expand JSON column
        json_df = pd.json_normalize(
            df[json_column].apply(json.loads)
        )
        
        # Combine with original data
        return pd.concat([df.drop(columns=[json_column]), json_df], axis=1)
```

## Load Patterns

### Batch Loading
```python
class DataLoader:
    def __init__(self, batch_size: int = 1000):
        self.batch_size = batch_size
    
    def load_to_database(self, df: pd.DataFrame, config: Dict) -> None:
        import sqlalchemy
        
        engine = sqlalchemy.create_engine(config['connection_string'])
        
        # Load in batches
        for i in range(0, len(df), self.batch_size):
            batch = df.iloc[i:i + self.batch_size]
            batch.to_sql(
                name=config['table'],
                con=engine,
                if_exists='append',
                index=False,
                method='multi'
            )
    
    def load_to_s3(self, df: pd.DataFrame, config: Dict) -> None:
        import boto3
        from io import StringIO
        
        s3 = boto3.client('s3')
        
        # Convert to CSV
        csv_buffer = StringIO()
        df.to_csv(csv_buffer, index=False)
        
        # Upload to S3
        s3.put_object(
            Bucket=config['bucket'],
            Key=config['key'],
            Body=csv_buffer.getvalue()
        )
```

### Upsert Pattern
```python
def upsert_data(df: pd.DataFrame, config: Dict) -> None:
    """Insert or update data based on primary key"""
    import sqlalchemy
    from sqlalchemy.dialects.postgresql import insert
    
    engine = sqlalchemy.create_engine(config['connection_string'])
    
    # Create insert statement
    meta = sqlalchemy.MetaData()
    table = sqlalchemy.Table(
        config['table'],
        meta,
        autoload_with=engine
    )
    
    # Prepare data
    data = df.to_dict('records')
    
    # Upsert operation
    stmt = insert(table).values(data)
    update_columns = {
        c.name: c for c in stmt.excluded
        if c.name not in config['primary_keys']
    }
    stmt = stmt.on_conflict_do_update(
        index_elements=config['primary_keys'],
        set_=update_columns
    )
    
    with engine.connect() as conn:
        conn.execute(stmt)
        conn.commit()
```

## Error Handling

### Robust Error Handling
```python
class ErrorHandler:
    def __init__(self, strategy: str = "fail"):
        self.strategy = strategy
        self.errors = []
    
    def handle_error(self, error: Exception, context: Dict) -> None:
        error_info = {
            'error': str(error),
            'type': type(error).__name__,
            'context': context,
            'timestamp': pd.Timestamp.now()
        }
        
        self.errors.append(error_info)
        
        if self.strategy == "fail":
            raise error
        elif self.strategy == "skip":
            self.log_error(error_info)
        elif self.strategy == "retry":
            self.retry_operation(context)
    
    def retry_operation(self, context: Dict, max_retries: int = 3):
        for attempt in range(max_retries):
            try:
                # Retry the operation
                return context['operation']()
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                time.sleep(2 ** attempt)  # Exponential backoff
```

## Data Quality

### Quality Checks
```python
class DataQualityChecker:
    def __init__(self):
        self.checks = []
    
    def add_check(self, name: str, check_func):
        self.checks.append((name, check_func))
    
    def run_checks(self, df: pd.DataFrame) -> Dict[str, bool]:
        results = {}
        
        for name, check_func in self.checks:
            try:
                results[name] = check_func(df)
            except Exception as e:
                results[name] = False
                print(f"Check {name} failed: {e}")
        
        return results

# Quality check functions
def check_completeness(df: pd.DataFrame, threshold: float = 0.95) -> bool:
    """Check if data completeness meets threshold"""
    completeness = 1 - (df.isnull().sum().sum() / (len(df) * len(df.columns)))
    return completeness >= threshold

def check_uniqueness(df: pd.DataFrame, columns: List[str]) -> bool:
    """Check if specified columns have unique values"""
    return not df.duplicated(subset=columns).any()

def check_range(df: pd.DataFrame, column: str, min_val: float, max_val: float) -> bool:
    """Check if values are within expected range"""
    return df[column].between(min_val, max_val).all()
```

## Orchestration

### DAG-based Pipeline
```python
from typing import Callable
from collections import defaultdict

class ETLTask:
    def __init__(self, name: str, func: Callable, dependencies: List[str] = None):
        self.name = name
        self.func = func
        self.dependencies = dependencies or []
        self.status = 'pending'
        self.result = None

class ETLOrchestrator:
    def __init__(self):
        self.tasks = {}
        self.results = {}
    
    def add_task(self, task: ETLTask):
        self.tasks[task.name] = task
    
    def run(self):
        # Topological sort for execution order
        execution_order = self._topological_sort()
        
        for task_name in execution_order:
            task = self.tasks[task_name]
            
            # Get dependency results
            dep_results = {
                dep: self.results[dep]
                for dep in task.dependencies
            }
            
            # Execute task
            try:
                task.result = task.func(**dep_results)
                task.status = 'completed'
                self.results[task.name] = task.result
            except Exception as e:
                task.status = 'failed'
                raise Exception(f"Task {task.name} failed: {e}")
    
    def _topological_sort(self) -> List[str]:
        visited = set()
        stack = []
        
        def dfs(task_name):
            visited.add(task_name)
            for dep in self.tasks[task_name].dependencies:
                if dep not in visited:
                    dfs(dep)
            stack.append(task_name)
        
        for task_name in self.tasks:
            if task_name not in visited:
                dfs(task_name)
        
        return stack[::-1]
```

## Checklist
- [ ] Define clear extraction strategy
- [ ] Implement data validation
- [ ] Add error handling
- [ ] Set up incremental processing
- [ ] Monitor data quality
- [ ] Implement idempotent operations
- [ ] Add logging and monitoring
- [ ] Document data lineage