# Inspecting TPR Files for Molecule Information

## Quick Summary

```bash
gmx dump -s <tpr_file> 2>&1 | grep -A 5 "moltype"
```

## Detailed Breakdown

```bash
# Full dump (verbose)
gmx dump -s <tpr_file>

# Extract molecule block info
gmx dump -s <tpr_file> 2>&1 | grep -E "(molblock|#molecules|moltype.*=)"
```

**Output interpretation:**
```
molblock (N):
   moltype              = M "MoleculeName"    # Molecule type name
   #molecules           = X                    # Number of copies in system

moltype (M):
   name="MoleculeName"
   atoms:
      atom (N):                              # N atoms in this molecule type
```

**Note:** Atoms are 0-indexed. `atom (275):` means 276 atoms with indices 0-275.

## Key Information to Extract

| Information | How to Find |
|-------------|-------------|
| Molecule type names | `grep 'moltype.*='` after `gmx dump` |
| Molecule counts | `grep '#molecules'` after `gmx dump` |
| Atoms per molecule type | Check `atom (N):` line under each `moltype` section |
| Solvent molecule count | Find SOL/Water moltype, read `#molecules` |
| Ion counts by type | Find NA, CL, etc. moltypes, read `#molecules` each |
| Protein molecule chains | Count moltypes with "Protein" or similar in name |

## Detecting Cyclic Molecule Configuration

For protein chains, check if the molecule is cyclic (e.g., cyclic peptides) by examining bonds within the moltype.

**Detection strategy:**
1. Get atom count for the moltype from `atom (N):` line (N atoms, indexed 0 to N-1)
2. Search the Bond section for a bond between atom 0 and the C-terminal atom (typically atom N-2, which is the C atom before the terminal O)
3. If such a bond exists, the molecule is cyclic

If no bond is found between atom 0 and the C-terminal atom, the molecule is linear (non-cyclic).

**Bond format in gmx dump:**
```
      Bond:
         nr: <count>
         iatoms:
            0 type=441 (BONDS)   0   2
            1 type=442 (BONDS)   0 273    <-- bond from atom 0 to atom 273
```

**Example:** For a 275-atom cyclic peptide (atoms 0-274):
- Atom 0: N-terminal N
- Atom 273: C-terminal C (the backbone carbon)
- Atom 274: C-terminal O
- A bond `0 273` indicates the N-C cyclization

**Quick check for cyclic bond:**
```bash
# Get atom count for a protein moltype
gmx dump -s <tpr_file> 2>&1 | grep -A 1 "atom (" | head -4

# Search for bonds involving atom 0 and the C-terminal atom (N-2)
# Replace <N-2> with actual value (e.g., 273 for 275-atom molecule)

# Standard pattern
gmx dump -s <tpr_file> 2>&1 | grep -E "BONDS.*0.*<N-2>"

# More robust pattern (explicit whitespace, works better on Windows)
gmx dump -s <tpr_file> 2>&1 | grep -E "BONDS\ +0 +<N-2>"
```

**Example command for 275-atom molecule:**
```bash
gmx dump -s <tpr_file> 2>&1 | grep -E "BONDS.*0.*273"
```

#### Verifying the C-Terminal Atom

The C-terminal C atom is typically at index N-2, but this can vary by force field. Verify with:
```bash
# Check atom type at index N-2 (e.g., 273 for 275-atom molecule)
gmx dump -s <tpr_file> 2>&1 | grep -A2 "atom (273):"
```
Look for `type="C"` to confirm it's the backbone carbon.

#### Isolating Bonds for a Specific Moltype

When multiple moltypes exist, grep captures all bonds. To isolate one moltype's bonds:

**Method 1: sed range (Recommended)**
```bash
# Extract bonds for moltype M (e.g., moltype 1)
gmx dump -s <tpr_file> 2>&1 | sed -n '/moltype (1)/,/moltype (2)/p' | grep -E "BONDS.*0.*273"
```

**Method 2: grep with context**
```bash
# Get bonds within 200 lines after moltype declaration
gmx dump -s <tpr_file> 2>&1 | grep -A200 "moltype (1)" | grep -E "BONDS.*0.*273"
```
Replace moltype numbers and context lines as appropriate for your system.

## Checking Molecule Independence

```bash
gmx dump -s <tpr_file> 2>&1 | grep "bIntermolecularInteractions"
```
- `false` = Molecules are independent (correct for most simulations)
- `true` = Bonded interactions exist between molecule types (unusual)

## Quick System Overview

```bash
echo "q" | gmx make_ndx -f <tpr_file> 2>&1 | grep -E "(System|Protein|Water|Ion|atoms)"
```

## Standardized TPR Summary Template

When users ask generic questions like "summarize this TPR" or "list all components", use this template for consistent output:

### <tpr_file> Analysis Summary

| Component | Count | Atoms | Structure |
|-----------|-------|-------|-----------|
| <moltype_name> | <N_copies> | <atoms_per_copy> | <Linear/Cyclic/-> |
| ... | ... | ... | ... |
| **Total** | - | **<sum_atoms>** | - |

**Key Information:**
- **Total protein residues**: <X> (<Y> atoms total)
- **Molecules are <independent/linked>** (bIntermolecularInteractions=<true/false>)
- <Notable features>

### Populating the Template

Use commands from:
- **Key Information to Extract** table → Component, Count, Atoms columns
- **Detecting Cyclic Molecule Configuration** → Structure column (Linear/Cyclic)
- **Checking Molecule Independence** → bIntermolecularInteractions value

### Structure Column Values

| Value | When to Use |
|-------|-------------|
| `Linear` | Standard protein/peptide without cyclization |
| `**Cyclic** (bond 0→<N-2>)` | N-to-C cyclization detected |
| `-` | Non-protein (solvent, ions, ligands) |
