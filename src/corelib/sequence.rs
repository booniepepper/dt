use crate::rail_machine::{self, RailDef, RailVal, Stack};

// TODO: These should all work for both String and Quote? Should String also be a Quote? Typeclasses?
pub fn builtins() -> Vec<RailDef<'static>> {
    vec![
        RailDef::on_state("len", &["quote|string"], &["i64"], |quote| {
            let (a, quote) = quote.pop();
            let len: i64 = match a {
                RailVal::Quote(quote) => quote.len(),
                RailVal::String(s) => s.len(),
                _ => {
                    rail_machine::log_warn(format!(
                        "Can only perform len on quote or string but got {}",
                        a
                    ));
                    return quote.push(a);
                }
            }
            .try_into()
            .unwrap();
            quote.push_i64(len)
        }),
        RailDef::on_state("quote", &["a"], &["quote"], |quote| {
            let (a, quote) = quote.pop();
            let wrapper = quote.child();
            let wrapper = wrapper.push(a);
            quote.push_quote(wrapper)
        }),
        RailDef::on_state("unquote", &["quote"], &["..."], |quote| {
            let (wrapper, mut quote) = quote.pop_quote("unquote");
            for value in wrapper.stack.values {
                quote = quote.push(value);
            }
            quote
        }),
        RailDef::on_state("push", &["quote", "a"], &["quote"], |quote| {
            let (a, quote) = quote.pop();
            let (sequence, quote) = quote.pop_quote("push");
            let sequence = sequence.push(a);
            quote.push_quote(sequence)
        }),
        RailDef::on_state("pop", &["quote"], &["quote", "a"], |quote| {
            let (sequence, quote) = quote.pop_quote("pop");
            let (a, sequence) = sequence.pop();
            quote.push_quote(sequence).push(a)
        }),
        RailDef::on_state("enq", &["a", "quote"], &["quote"], |quote| {
            let (sequence, quote) = quote.pop_quote("push");
            let (a, quote) = quote.pop();
            let sequence = sequence.enqueue(a);
            quote.push_quote(sequence)
        }),
        RailDef::on_state("nth", &["quote", "i64"], &["a"], |state| {
            let (nth, state) = state.pop_i64("nth");
            let (seq, state) = state.pop_quote("nth");

            let nth = seq.stack.values.get(nth as usize).unwrap();

            state.push(nth.clone())
        }),
        RailDef::on_state("deq", &["quote"], &["a", "quote"], |quote| {
            let (sequence, quote) = quote.pop_quote("pop");
            let (a, sequence) = sequence.dequeue();
            quote.push(a).push_quote(sequence)
        }),
        RailDef::on_state("rev", &["quote"], &["quote"], |quote| {
            let (sequence, quote) = quote.pop_quote("rev");
            let sequence = sequence.reverse();
            quote.push_quote(sequence)
        }),
        RailDef::on_state("concat", &["quote", "quote"], &["quote"], |quote| {
            let (suffix, quote) = quote.pop_quote("concat");
            let (prefix, quote) = quote.pop_quote("concat");
            let mut results = quote.child();
            for term in prefix.stack.values.into_iter().chain(suffix.stack.values) {
                results = results.push(term);
            }
            quote.push_quote(results)
        }),
        RailDef::on_state("filter", &["quote", "quote"], &["quote"], |state| {
            let (predicate, state) = state.pop_quote("filter");
            let (sequence, state) = state.pop_quote("filter");
            let mut results = state.child();

            for term in sequence.stack.values {
                let substate = state.child().replace_stack(Stack::of(term.clone()));
                let substate = predicate.clone().jailed_run_in_state(substate);
                let (keep, _) = substate.stack.pop_bool("filter");
                if keep {
                    results = results.push(term);
                }
            }

            state.push_quote(results)
        }),
        RailDef::on_state("map", &["quote", "quote"], &["quote"], |state| {
            let (transform, state) = state.pop_quote("map");
            let (sequence, state) = state.pop_quote("map");

            let mut results = state.child();

            for term in sequence.stack.values {
                results = results.push(term.clone());
                let substate = state.child().replace_stack(results.stack);
                let substate = transform.clone().jailed_run_in_state(substate);
                results = substate;
            }

            state.push_quote(results)
        }),
        RailDef::on_state("each!", &["quote", "quote"], &[], |state| {
            let (command, quote) = state.stack.clone().pop_quote("each");
            let (sequence, quote) = quote.pop_quote("each");

            let state = state.replace_stack(quote);

            sequence
                .stack
                .values
                .into_iter()
                .fold(state, |state, value| {
                    let state = state.update_stack(|quote| quote.push(value.clone()));
                    command.clone().run_in_state(state)
                })
        }),
        RailDef::on_jailed_state("each", &["quote", "quote"], &[], |state| {
            let (command, quote) = state.stack.clone().pop_quote("each");
            let (sequence, quote) = quote.pop_quote("each");

            let state = state.replace_stack(quote);

            let definitions = state.definitions.clone();

            sequence
                .stack
                .values
                .into_iter()
                .fold(state, |state, value| {
                    let state = state
                        .update_stack(|quote| quote.push(value.clone()))
                        .replace_definitions(definitions.clone());
                    command.clone().jailed_run_in_state(state)
                })
        }),
        RailDef::on_state("zip", &["quote", "quote"], &["quote"], |state| {
            let (b, state) = state.pop_quote("zip");
            let (a, state) = state.pop_quote("zip");

            let c = a
                .stack
                .values
                .into_iter()
                .zip(b.stack.values)
                .map(|(a, b)| state.child().push(a).push(b))
                .fold(state.child(), |c, quote| c.push_quote(quote));

            state.push_quote(c)
        }),
        RailDef::on_state("zip-with", &["quote", "quote", "quote"], &["quote"], |state| {
            let (xform, state) = state.pop_quote("zip-with");
            let (b, state) = state.pop_quote("zip-with");
            let (a, state) = state.pop_quote("zip-with");

            let c = a
                .stack
                .values
                .into_iter()
                .zip(b.stack.values)
                .map(|(a, b)| state.child().push(a).push(b))
                .map(|ab| xform.clone().run_in_state(ab))
                .fold(state.child(), |c, result| c.push_quote(result));

            state.push_quote(c)
        }),
    ]
}
