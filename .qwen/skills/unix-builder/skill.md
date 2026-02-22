# Unix Pipeline Builder Skill

## Purpose
Guide users in solving problems using the Unix philosophy: "Do one thing and do it well." Interview the user about their task, then suggest elegant solutions using base Unix/Linux tools connected via pipes, demonstrating how small, focused tools can be composed to solve complex problems.

## What This Skill Provides
- Task decomposition into Unix-style operations
- Tool selection based on Unix philosophy
- Pipeline construction with proper error handling
- Alternative approaches and optimizations
- Educational explanations of why each tool is chosen
- Common patterns and idioms

## Unix Philosophy Principles

### Core Tenets
1. **Do one thing and do it well** - Each tool has a single, focused purpose
2. **Work together** - Tools accept input and produce output in simple, universal formats
3. **Handle text streams** - Text is the universal interface
4. **Avoid captive user interfaces** - Tools should be composable
5. **Make each program a filter** - Read from stdin, write to stdout

### Pipeline Thinking
- Break complex tasks into simple transformations
- Chain tools using pipes (`|`)
- Each stage processes and passes data forward
- Error streams (`stderr`) separate from data streams (`stdout`)
- Exit codes indicate success/failure

## Interview Process

### Step 1: Understand the Task
Ask the user:
- **"What are you trying to accomplish?"**
  - Extract data from a file
  - Transform data format
  - Filter/search content
  - Monitor system resources
  - Process log files
  - Automate repetitive tasks
  - Analyze text/data
  - Generate reports

### Step 2: Identify Input
Ask the user:
- **"What is your input?"**
  - File (what format: text, csv, json, xml, log)?
  - Command output
  - Multiple files
  - Stream of data
  - User input
  - Network data
- **"Can you provide an example?"** (small sample of actual input)

### Step 3: Define Output
Ask the user:
- **"What should the output look like?"**
  - Filtered/selected lines
  - Transformed format
  - Aggregated statistics
  - Sorted/ordered data
  - Report format
  - Multiple output files
- **"Can you show me what you expect?"** (example of desired output)

### Step 4: Constraints & Environment
Ask the user:
- **"Any constraints?"**
  - Performance requirements
  - Memory limitations
  - File size considerations
  - Portability needs (POSIX compliance)
  - System type (Linux, BSD, macOS)
  - Available tools (busybox, GNU coreutils, etc.)

### Step 5: Error Handling
Ask the user:
- **"How should errors be handled?"**
  - Fail fast or continue on errors
  - Log errors to file
  - Retry logic needed
  - Validation requirements

## Tool Categories

### Text Processing
- **grep** - Pattern matching and filtering
- **sed** - Stream editing and transformation
- **awk** - Text processing and data extraction
- **cut** - Extract columns/fields
- **tr** - Character translation/deletion
- **paste** - Merge files line by line
- **join** - Join files on common fields
- **sort** - Sort lines
- **uniq** - Filter duplicate lines
- **head/tail** - Extract beginning/end of files
- **wc** - Count lines/words/characters

### File Operations
- **cat** - Concatenate and display
- **tee** - Read stdin, write to stdout and files
- **split** - Split files into pieces
- **find** - Search filesystem
- **xargs** - Build command lines from input

### Data Transformation
- **jq** - JSON processor (if available)
- **xmllint** - XML processor (if available)
- **iconv** - Character encoding conversion
- **od/hexdump** - Octal/hex dump
- **base64** - Base64 encoding/decoding

### System & Monitoring
- **ps** - Process status
- **top/htop** - System monitoring
- **df/du** - Disk usage
- **netstat/ss** - Network statistics
- **vmstat** - Virtual memory statistics
- **iostat** - I/O statistics

### Network
- **curl/wget** - Transfer data from URLs
- **nc (netcat)** - Network connections
- **ping** - Test connectivity
- **dig/nslookup** - DNS queries

### Utilities
- **date** - Date/time operations
- **bc** - Calculator
- **seq** - Generate sequences
- **yes** - Repeat strings
- **sleep** - Delay execution
- **timeout** - Run command with timeout

## Solution Construction

### Template Structure

For each solution, provide:

```markdown
## Solution: [Brief Description]

### Pipeline
[Show the complete pipeline]

### Breakdown
[Explain each component]

### Why This Approach?
[Explain the Unix philosophy reasoning]

### Variations
[Show alternative approaches]

### Error Handling
[Add error checking]

### Optimization
[Performance tips if relevant]
```

### Example Format

```bash
# Pipeline
command1 | command2 | command3 > output.txt

# Step-by-step breakdown:
# 1. command1: [what it does, why chosen]
# 2. command2: [what it does, why chosen]
# 3. command3: [what it does, why chosen]
```

## Common Patterns

### Pattern 1: Filter → Transform → Output
```bash
# Extract lines matching pattern, modify them, save result
grep "pattern" input.txt | sed 's/old/new/' | sort > output.txt
```
**When to use**: Most text processing tasks

### Pattern 2: Generate → Process → Aggregate
```bash
# Create data, transform it, summarize
seq 1 100 | awk '{sum+=$1} END {print sum}'
```
**When to use**: Mathematical or statistical operations

### Pattern 3: Find → Execute
```bash
# Locate files, perform action on each
find . -name "*.log" -type f | xargs grep "ERROR"
```
**When to use**: Bulk file operations

### Pattern 4: Monitor → Filter → Alert
```bash
# Watch for condition, filter relevant, take action
tail -f /var/log/syslog | grep "ERROR" | while read line; do echo "$line" | mail -s "Alert" admin@example.com; done
```
**When to use**: Real-time monitoring

### Pattern 5: Multiple Inputs → Join → Transform
```bash
# Combine data from sources, process together
cat file1.txt file2.txt | sort | uniq -c | sort -rn
```
**When to use**: Aggregating from multiple sources

### Pattern 6: Validate → Process → Split
```bash
# Check input, transform, separate output
grep -v "^#" input.txt | awk '{print > $1".txt"}'
```
**When to use**: Data routing based on content

### Pattern 7: Parallel Processing
```bash
# Process chunks in parallel
cat large_file.txt | xargs -P 4 -n 1000 process_chunk.sh
```
**When to use**: Performance-critical large file processing

### Pattern 8: Incremental Processing with State
```bash
# Track state across processing
awk 'BEGIN {count=0} /pattern/ {count++} END {print count}' input.txt
```
**When to use**: Stateful transformations

## Pipeline Best Practices

### Robustness
```bash
# Good: Check for file existence
if [ -f "input.txt" ]; then
    cat input.txt | grep "pattern"
fi

# Good: Handle missing input gracefully
grep "pattern" input.txt 2>/dev/null || echo "No matches found"

# Good: Use set -e for error propagation in scripts
set -e
set -o pipefail  # Catch errors in pipelines
```

### Efficiency
```bash
# Bad: Unnecessary cat (UUOC - Useless Use Of Cat)
cat file.txt | grep "pattern"

# Good: Direct input
grep "pattern" file.txt

# Bad: Multiple passes over data
cat file.txt | grep "foo" > temp.txt
cat temp.txt | sed 's/bar/baz/' > output.txt

# Good: Single pass
grep "foo" file.txt | sed 's/bar/baz/' > output.txt
```

### Readability
```bash
# Complex one-liner (hard to understand)
cat file.txt | grep -v "^#" | awk '{print $2}' | sort | uniq -c | sort -rn | head -10

# Better: Break into steps with comments
cat file.txt |           # Read input
grep -v "^#" |           # Remove comments
awk '{print $2}' |       # Extract second field
sort |                    # Sort for uniq
uniq -c |                # Count occurrences
sort -rn |               # Sort by count descending
head -10                 # Top 10

# Or use backslashes for multi-line
cat file.txt \
  | grep -v "^#" \
  | awk '{print $2}' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10
```

### Debugging
```bash
# Insert tee to see intermediate results
cat file.txt | grep "pattern" | tee debug.txt | sed 's/foo/bar/'

# Use set -x to trace execution
set -x
pipeline commands here
set +x

# Check exit codes
command1 | command2
echo "Pipeline exit code: $?"
```

## Advanced Techniques

### Named Pipes (FIFOs)
```bash
# Process two streams simultaneously
mkfifo pipe1
command1 > pipe1 &
command2 < pipe1 | command3
rm pipe1
```

### Process Substitution
```bash
# Compare output of two commands
diff <(command1) <(command2)

# Multiple inputs without temp files
paste <(cut -f1 file1.txt) <(cut -f2 file2.txt)
```

### Here Documents
```bash
# Inline input
command <<EOF
line1
line2
EOF
```

### Command Substitution
```bash
# Use command output as argument
grep "pattern" $(find . -name "*.txt")

# Or with backticks (older style)
grep "pattern" `find . -name "*.txt"`
```

### Subshells
```bash
# Isolate environment changes
(cd /tmp && do_something)  # Returns to original directory
# pwd shows original directory
```

## Example Solutions

### Example 1: Log Analysis
**Task**: Find the top 10 most frequent error messages in a log file

**Input**: `/var/log/application.log`
```
2024-02-12 10:23:45 ERROR Database connection failed
2024-02-12 10:23:46 INFO User logged in
2024-02-12 10:23:47 ERROR Database connection failed
2024-02-12 10:23:48 ERROR File not found: config.xml
```

**Solution**:
```bash
# Pipeline
grep "ERROR" /var/log/application.log | 
  sed 's/^[0-9-]* [0-9:]* ERROR //' | 
  sort | 
  uniq -c | 
  sort -rn | 
  head -10

# Breakdown:
# 1. grep "ERROR" - Filter only error lines (do one thing: filter)
# 2. sed - Remove timestamp prefix (do one thing: clean)
# 3. sort - Prepare for uniq (required for uniq to work)
# 4. uniq -c - Count occurrences (do one thing: count)
# 5. sort -rn - Sort by count, descending (do one thing: order)
# 6. head -10 - Take top 10 (do one thing: limit)
```

**Why This Approach?**
- Each tool has single responsibility
- Data flows naturally left to right
- Easy to modify (add filter, change count, etc.)
- No temporary files needed
- Works with arbitrarily large log files (streaming)

**Variation with AWK** (more efficient for large files):
```bash
awk '/ERROR/ {
  gsub(/^[0-9-]* [0-9:]* ERROR /, "")
  count[$0]++
}
END {
  for (msg in count) 
    print count[msg], msg
}' /var/log/application.log | 
  sort -rn | 
  head -10
```

### Example 2: CSV to JSON Conversion
**Task**: Convert a CSV file to JSON format

**Input**: `users.csv`
```
name,email,age
John Doe,john@example.com,30
Jane Smith,jane@example.com,25
```

**Solution**:
```bash
# Simple approach with awk
awk -F',' '
NR==1 {
  # Store headers
  for (i=1; i<=NF; i++) header[i]=$i
  next
}
{
  # Build JSON for each row
  printf "{"
  for (i=1; i<=NF; i++) {
    printf "\"%s\":\"%s\"", header[i], $i
    if (i<NF) printf ","
  }
  printf "}\n"
}' users.csv

# Output:
# {"name":"John Doe","email":"john@example.com","age":"30"}
# {"name":"Jane Smith","email":"jane@example.com","age":"25"}

# Wrap in array (if needed):
echo "["
awk -F',' '...(same as above)...' users.csv | sed '$!s/$/,/'
echo "]"
```

**Why AWK?**
- Built-in field splitting (handles CSV)
- Maintains state (headers)
- Procedural logic for complex transformation
- Single pass through data

### Example 3: File Monitoring and Alerting
**Task**: Monitor directory for new .txt files and email notification

**Solution**:
```bash
# Using inotifywait (Linux)
inotifywait -m -e create --format '%f' /path/to/watch |
  grep '\.txt$' |
  while read filename; do
    echo "New file: $filename" | 
      mail -s "File Alert" admin@example.com
  done

# Breakdown:
# 1. inotifywait - Monitor filesystem events (specialized tool)
# 2. grep - Filter only .txt files (do one thing: filter)
# 3. while read - Process each event (standard input loop)
# 4. mail - Send notification (do one thing: communicate)
```

**Alternative (Portable - using polling)**:
```bash
# Compare directory listings periodically
watch_dir="/path/to/watch"
interval=5

find "$watch_dir" -name "*.txt" > /tmp/files.old

while true; do
  sleep $interval
  find "$watch_dir" -name "*.txt" > /tmp/files.new
  
  # Find new files
  comm -13 /tmp/files.old /tmp/files.new |
    while read newfile; do
      echo "New file: $newfile" | 
        mail -s "File Alert" admin@example.com
    done
  
  mv /tmp/files.new /tmp/files.old
done
```

### Example 4: Data Aggregation
**Task**: Sum values by category from a data file

**Input**: `sales.txt`
```
Electronics 150
Clothing 200
Electronics 300
Furniture 100
Clothing 150
```

**Solution**:
```bash
# Using awk (most efficient)
awk '{sum[$1]+=$2} END {for (cat in sum) print cat, sum[cat]}' sales.txt | sort

# Output:
# Clothing 350
# Electronics 450
# Furniture 100

# Alternative using sort/uniq (if awk not available)
sort sales.txt | 
  awk '{
    if ($1 == prev) {
      total += $2
    } else {
      if (prev) print prev, total
      prev = $1
      total = $2
    }
  }
  END {print prev, total}'
```

**Why AWK?**
- Associative arrays for grouping
- Built-in arithmetic
- Single pass through data
- Clear, readable logic

### Example 5: Text Extraction and Formatting
**Task**: Extract all email addresses from multiple files and create unique sorted list

**Solution**:
```bash
# Pipeline
find . -type f -name "*.txt" | 
  xargs grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | 
  sort -u > emails.txt

# Breakdown:
# 1. find - Locate all .txt files (do one thing: search files)
# 2. xargs - Build grep commands (do one thing: execute)
# 3. grep -oE - Extract email pattern (do one thing: match)
# 4. sort -u - Sort and remove duplicates (combined for efficiency)

# Why -o flag? Outputs only the matched part, not whole line
# Why xargs? Handles many files efficiently, avoids "argument list too long"
```

**With validation**:
```bash
# Add email validation using additional filter
find . -type f -name "*.txt" | 
  xargs grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | 
  awk '{
    # Split email into parts
    split($0, parts, "@")
    if (length(parts[1]) > 0 && length(parts[2]) > 0)
      print tolower($0)  # Normalize to lowercase
  }' |
  sort -u > emails.txt
```

### Example 6: System Resource Monitoring
**Task**: Track memory usage of a specific process over time

**Solution**:
```bash
# Real-time monitoring
watch_process="nginx"

echo "timestamp,pid,memory_mb" > memory_log.csv

while true; do
  ps aux | 
    grep "$watch_process" | 
    grep -v grep | 
    awk -v date="$(date +%s)" '{
      printf "%s,%s,%.2f\n", date, $2, $6/1024
    }' >> memory_log.csv
  
  sleep 60
done

# Breakdown:
# 1. ps aux - Get process info (do one thing: list processes)
# 2. grep - Filter target process (do one thing: filter)
# 3. grep -v grep - Remove grep itself (clean filter)
# 4. awk - Format and calculate (do one thing: transform)

# Analysis pipeline:
tail -100 memory_log.csv | 
  awk -F',' '{sum+=$3; count++} END {print "Avg:", sum/count, "MB"}'
```

### Example 7: Batch File Renaming
**Task**: Rename all .jpeg files to .jpg

**Solution**:
```bash
# Safe approach with preview
find . -name "*.jpeg" -type f | 
  sed 'p;s/\.jpeg$/.jpg/' | 
  xargs -n2 echo mv

# Remove 'echo' to actually rename:
find . -name "*.jpeg" -type f | 
  sed 'p;s/\.jpeg$/.jpg/' | 
  xargs -n2 mv

# Breakdown:
# 1. find - Locate .jpeg files (do one thing: search)
# 2. sed 'p;s/...' - Print original, then transformed (creates pairs)
# 3. xargs -n2 - Take two arguments at a time (old, new)
# 4. mv - Rename (do one thing: move/rename)

# Alternative with rename command (if available):
find . -name "*.jpeg" -type f -exec rename 's/\.jpeg$/.jpg/' {} +
```

### Example 8: Parallel Processing
**Task**: Process large file in parallel chunks

**Solution**:
```bash
# Split, process, merge
file="large_data.txt"
num_cores=$(nproc)

# Split into chunks
split -n l/$num_cores $file chunk_

# Process in parallel
ls chunk_* | 
  xargs -P $num_cores -I {} sh -c '
    cat {} | 
    process_command | 
    sort > {}.processed
  '

# Merge results
sort -m chunk_*.processed > final_output.txt

# Cleanup
rm chunk_* chunk_*.processed

# Breakdown:
# 1. split - Divide file (do one thing: partition)
# 2. xargs -P - Parallel execution (do one thing: parallelize)
# 3. sort -m - Merge sorted files (do one thing: merge)
```

### Example 9: Configuration File Processing
**Task**: Extract specific settings from multiple config files

**Solution**:
```bash
# Find all configs, extract setting, format output
find /etc -name "*.conf" 2>/dev/null | 
  xargs grep -H "^MaxConnections" | 
  sed 's/:MaxConnections=/,/' | 
  awk -F',' '{printf "%-50s %s\n", $1, $2}' | 
  sort -k2 -rn

# Breakdown:
# 1. find - Locate config files (suppress permission errors with 2>/dev/null)
# 2. grep -H - Search with filename (do one thing: search)
# 3. sed - Transform to CSV (do one thing: format)
# 4. awk - Pretty print (do one thing: display)
# 5. sort -k2 -rn - Sort by value (do one thing: order)

# Output example:
# /etc/nginx/nginx.conf                              1024
# /etc/mysql/my.cnf                                  512
# /etc/apache2/apache2.conf                          256
```

### Example 10: Data Validation
**Task**: Validate CSV file structure and content

**Solution**:
```bash
# Check for consistent column count
awk -F',' '
NR==1 {
  expected_cols = NF
  next
}
NF != expected_cols {
  print "Line", NR, "has", NF, "columns, expected", expected_cols
  errors++
}
END {
  if (errors) 
    print "Total errors:", errors
  else 
    print "File structure valid"
}' data.csv

# Validate email format in column 2
awk -F',' '
NR==1 {next}  # Skip header
$2 !~ /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/ {
  print "Invalid email on line", NR ":", $2
}' data.csv

# Validate numeric column
awk -F',' '
NR==1 {next}
$3 !~ /^[0-9]+$/ {
  print "Non-numeric value on line", NR ":", $3
}' data.csv

# Combine all validations
awk -F',' '
NR==1 {
  expected_cols = NF
  next
}
{
  # Check column count
  if (NF != expected_cols) 
    print "Line", NR, ": column count mismatch"
  
  # Check email format
  if ($2 !~ /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)
    print "Line", NR, ": invalid email"
  
  # Check numeric field
  if ($3 !~ /^[0-9]+$/)
    print "Line", NR, ": non-numeric age"
}' data.csv
```

## Troubleshooting Common Issues

### Issue: "Broken pipe" errors
**Cause**: Downstream command exits before upstream completes
```bash
# Example that might break
cat huge_file.txt | head -10

# Solution: Ignore SIGPIPE
cat huge_file.txt 2>/dev/null | head -10

# Or use timeout
timeout 5 cat huge_file.txt | head -10
```

### Issue: "Argument list too long"
**Cause**: Too many arguments to command
```bash
# Bad
grep "pattern" *.txt

# Good: Use find with xargs
find . -name "*.txt" -print0 | xargs -0 grep "pattern"

# Or: Use find with -exec
find . -name "*.txt" -exec grep "pattern" {} +
```

### Issue: Spaces in filenames
```bash
# Bad: Breaks on spaces
for file in $(find . -name "*.txt"); do
  process $file
done

# Good: Use while read with null delimiter
find . -name "*.txt" -print0 | while IFS= read -r -d '' file; do
  process "$file"
done

# Or: Use find -exec
find . -name "*.txt" -exec process {} \;
```

### Issue: Special characters in data
```bash
# Escape special characters
sed 's/\$/DOLLAR/g' file.txt

# Or use different delimiter in sed
sed 's|/path/to/old|/path/to/new|g' file.txt

# Quote variables properly
grep "$variable" file.txt  # Good
grep $variable file.txt    # Bad: word splitting
```

### Issue: Performance with large files
```bash
# Bad: Multiple passes
grep "foo" huge.txt > temp1
grep "bar" temp1 > temp2

# Good: Single pass
grep "foo" huge.txt | grep "bar"

# Even better: Combined pattern
grep -E "foo.*bar|bar.*foo" huge.txt

# Best: Use awk for complex logic
awk '/foo/ && /bar/' huge.txt
```

## Performance Considerations

### When to Use Each Tool

**grep vs awk vs sed**:
```bash
# Use grep for: Simple pattern matching
grep "pattern" file.txt

# Use awk for: Field processing, calculations, complex logic
awk '{sum+=$2} END {print sum}' file.txt

# Use sed for: Stream editing, substitutions
sed 's/old/new/g' file.txt
```

**Buffer Sizes**:
```bash
# Increase buffer for better performance
grep --line-buffered "pattern" | other_command

# Or use larger block sizes
dd if=input.txt bs=1M | process
```

**Parallel Processing**:
```bash
# GNU Parallel (if available)
cat file.txt | parallel --pipe --block 10M process

# Or xargs with -P
cat file.txt | xargs -P 4 -n 1000 process
```

## Common Anti-Patterns to Avoid

### 1. Useless Use of Cat (UUOC)
```bash
# Bad
cat file.txt | grep "pattern"

# Good
grep "pattern" file.txt
```

### 2. Unnecessary Subshells
```bash
# Bad
result=$(cat file.txt | grep "pattern" | wc -l)

# Good
result=$(grep -c "pattern" file.txt)
```

### 3. Not Using Built-in Features
```bash
# Bad: Count lines with wc
grep "pattern" file.txt | wc -l

# Good: Use grep's count
grep -c "pattern" file.txt
```

### 4. Inefficient Loops
```bash
# Bad: Process line by line in shell
while read line; do
  echo "$line" | do_something
done < file.txt

# Good: Let awk handle it
awk '{do_something}' file.txt
```

### 5. Not Handling Errors
```bash
# Bad: Ignore errors
command1 | command2 | command3

# Good: Check pipeline success
set -o pipefail
command1 | command2 | command3
if [ $? -ne 0 ]; then
  echo "Pipeline failed" >&2
  exit 1
fi
```

## Output Structure

For each solution, provide:

```markdown
# Task: [User's Goal]

## Input
[Description and sample]

## Output
[Expected result and sample]

## Solution

### Pipeline
```bash
[Complete command pipeline]
```

### Explanation
[Step-by-step breakdown with Unix philosophy principles]

### Why This Approach?
[Reasoning behind tool choices]

### Alternatives
[Other ways to solve the same problem]

### Error Handling
[How to make it robust]

### Performance Notes
[Optimization tips if relevant]

## Testing
[How to verify it works]
```

## Quick Reference: Tool Selection Guide

| Task | Primary Tool | Alternative | Notes |
|------|-------------|-------------|--------|
| Pattern matching | grep | awk | Use grep for simple, awk for complex |
| Field extraction | cut | awk | cut for fixed positions, awk for flexible |
| Text substitution | sed | awk | sed for simple replace, awk for conditional |
| Calculations | awk | bc | awk for text+math, bc for pure math |
| Sorting | sort | awk (rarely) | Always use sort for ordering |
| Counting unique | uniq -c | awk | Must sort before uniq |
| File finding | find | ls + grep | Always use find for robustness |
| Parallel execution | xargs -P | GNU parallel | xargs is POSIX, parallel has more features |
| JSON processing | jq | awk/sed | jq if available, awk/sed for portability |
| Monitoring | tail -f | watch | tail for files, watch for commands |

## Learning Resources

### Practice Exercises
After creating a pipeline, ask yourself:
1. Can I remove any tool? (Do less)
2. Can I combine operations? (More efficient)
3. Does each tool do one thing? (Unix philosophy)
4. Is it readable? (Maintainability)
5. Does it handle errors? (Robustness)

### Testing Your Pipeline
```bash
# Create test data
cat > test_input.txt <<EOF
line 1
line 2
line 3
EOF

# Test pipeline
cat test_input.txt | your_pipeline

# Verify output
diff expected_output.txt actual_output.txt
```

### Documentation Template
```bash
#!/bin/bash
# Purpose: [What this does]
# Input: [Description]
# Output: [Description]
# Usage: ./script.sh [arguments]

# Pipeline explanation:
# 1. [Step 1]
# 2. [Step 2]
# ...
```

## Remember

**Unix Philosophy in Practice:**
- Write programs that do one thing and do it well
- Write programs to work together
- Write programs to handle text streams, because that is a universal interface

**Pipeline Design:**
- Think in terms of data transformation
- Each stage is a filter
- Composability is key
- Text is the universal format

**When in Doubt:**
- Start simple
- Test each stage independently
- Add complexity only when needed
- Document your reasoning
