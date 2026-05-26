# Creating Index Files for Protein Chains

## Basic Method

```bash
# Interactive mode
gmx make_ndx -f <tpr_file> -o <index_file.ndx>

# Non-interactive: split protein group by chain
printf "splitch <protein_group>\nq\n" | gmx make_ndx -f <tpr_file> -o <index_file.ndx>
```

## Caveat: `splitch` Artefacts

`splitch` uses topological connectivity and may incorrectly split a single chain into multiple groups when:
- Hydrogen atoms were rebuilt by `pdb2gmx` (N-terminal residues get extra H1/H2/H3 atoms)
- Residue numbering has gaps (e.g., residues 1-18, then 26-108)

**Symptom**: After `splitch`, a single protein chain appears as multiple `Protein_chainN` groups where the atom counts don't match expected molecule boundaries.

## Recommended Workflow: Fix Incorrectly Split Chains

**Step 1: Identify the incorrect split**
After `splitch`, press Enter (empty line) in `make_ndx` to list all groups. Compare atom counts against your expected molecule sizes.

**Step 2: Merge the incorrectly split groups**
```
<group_N> | <group_M>
```
This creates a new merged group named `Protein_chainN_Protein_chainM` at the end of the list.

**Step 3: Verify the merged group**
Press Enter to list groups again. The merged group should have the correct total atom count.

**Step 4: Delete the incorrect split groups**
Delete in DESCENDING order to avoid index shifting confusion:
```
del <higher_index>
del <lower_index>
```
After `k` deletions, the merged group index shifts down by `k`.

**Step 5: Rename the merged group (optional)**
```
name <final_index> <custom_name>
```

## Generic Example (interactive `make_ndx` session)

```
> splitch 1
Found N chains
 1:  XXX atoms (a to b)
 2:   YY atoms (c to d)     <-- suspiciously small, may be incorrect split
 3:  ZZZ atoms (e to f)     <-- remainder of same chain

>                          <-- press Enter to list groups
...
 N  Protein_chain1         XXX atoms
N+1 Protein_chain2          YY atoms   <-- wrong split (too small)
N+2 Protein_chain3         ZZZ atoms   <-- wrong split (remainder)
...

> N+1 | N+2                 <-- merge the incorrectly split groups
Merged two groups with OR: YY ZZZ -> (YY+ZZZ)

>                          <-- press Enter to verify
...
 M  Protein_chain2_Protein_chain3   (YY+ZZZ) atoms   <-- correct total!

> del N+2                   <-- delete higher index first
> del N+1                   <-- then lower index

>                          <-- press Enter
...
 M-2  Protein_chain2_Protein_chain3   (YY+ZZZ) atoms   <-- shifted!

> name M-2 <your_chain_name>
> q
```

**Key insight**: After deleting `k` groups that were created AFTER the merged group, the merged group's index decreases by `k`.

## Non-interactive Equivalent

```bash
printf "splitch 1\n<group_N> | <group_M>\ndel <higher>\ndel <lower>\nname <final> <name>\nq\n" | \
  gmx make_ndx -f <tpr_file> -o <index_file.ndx>
```

## Creating C-alpha Groups

In `make_ndx` interactive mode:
```
a CA & <chain_group>      # creates C-alpha selection for specified chain
```
